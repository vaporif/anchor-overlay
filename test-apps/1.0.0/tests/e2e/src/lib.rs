#[cfg(test)]
mod tests {
    use sha2::Digest;
    use solana_client::rpc_client::RpcClient;
    use solana_sdk::{
        commitment_config::CommitmentConfig,
        instruction::{AccountMeta, Instruction},
        pubkey::Pubkey,
        signature::{Keypair, Signer},
        system_program::ID as SYSTEM_PROGRAM_ID,
        transaction::Transaction,
    };
    use std::{
        env, fs,
        process::{Child, Command},
        str::FromStr,
        thread,
        time::Duration,
    };

    const PROGRAM_ID: &str = "GVXHCbeuKKgTs2EbD7jtZr63DeNggWB4X5w6tHBnnpeS";

    fn find_free_port() -> u16 {
        std::net::TcpListener::bind("127.0.0.1:0")
            .unwrap()
            .local_addr()
            .unwrap()
            .port()
    }

    struct TestValidator {
        child: Child,
    }

    impl TestValidator {
        fn start(rpc_port: u16, faucet_port: u16, program_id: &Pubkey, so_path: &str) -> Self {
            let child = Command::new("solana-test-validator")
                .arg("--rpc-port")
                .arg(rpc_port.to_string())
                .arg("--faucet-port")
                .arg(faucet_port.to_string())
                .arg("--bpf-program")
                .arg(program_id.to_string())
                .arg(so_path)
                .arg("--reset")
                .arg("--quiet")
                .arg("--ledger")
                .arg(format!("/tmp/test-ledger-{rpc_port}"))
                .spawn()
                .expect("failed to start solana-test-validator");

            TestValidator { child }
        }
    }

    impl Drop for TestValidator {
        fn drop(&mut self) {
            let _ = self.child.kill();
            let _ = self.child.wait();
        }
    }

    fn wait_for_validator(rpc_url: &str, timeout_secs: u64) {
        let client = RpcClient::new(rpc_url.to_string());
        let deadline = std::time::Instant::now() + Duration::from_secs(timeout_secs);
        while std::time::Instant::now() < deadline {
            if client.get_health().is_ok() {
                return;
            }
            thread::sleep(Duration::from_millis(500));
        }
        panic!("validator did not become healthy within {timeout_secs}s");
    }

    /// Compute the Anchor instruction discriminator: first 8 bytes of sha256("global:<name>")
    fn instruction_discriminator(name: &str) -> [u8; 8] {
        let mut hasher = sha2::Sha256::new();
        hasher.update(format!("global:{name}").as_bytes());
        let hash = hasher.finalize();
        let mut disc = [0u8; 8];
        disc.copy_from_slice(&hash[..8]);
        disc
    }

    #[test]
    fn test_initialize_stores_value_and_bump() {
        let so_path = env::var("PROGRAM_SO_PATH")
            .expect("set PROGRAM_SO_PATH to the .so file built by nix");

        assert!(
            fs::metadata(&so_path).is_ok(),
            "program .so not found at {so_path}"
        );

        let program_id = Pubkey::from_str(PROGRAM_ID).unwrap();
        let rpc_port = find_free_port();
        let faucet_port = find_free_port();
        let rpc_url = format!("http://127.0.0.1:{rpc_port}");

        let _validator = TestValidator::start(rpc_port, faucet_port, &program_id, &so_path);
        wait_for_validator(&rpc_url, 30);

        let rpc = RpcClient::new_with_commitment(rpc_url, CommitmentConfig::confirmed());

        // Fund a payer
        let payer = Keypair::new();
        let sig = rpc
            .request_airdrop(&payer.pubkey(), 2_000_000_000)
            .expect("airdrop failed");
        rpc.confirm_transaction(&sig).unwrap();
        // Wait for the airdrop to land
        loop {
            let balance = rpc.get_balance(&payer.pubkey()).unwrap();
            if balance >= 2_000_000_000 {
                break;
            }
            thread::sleep(Duration::from_millis(200));
        }

        // Derive the PDA: seeds = [b"data", signer.key()]
        let (data_pda, expected_bump) =
            Pubkey::find_program_address(&[b"data", payer.pubkey().as_ref()], &program_id);

        // Build the initialize instruction with value = 42
        let value: u64 = 42;
        let disc = instruction_discriminator("initialize");
        let mut data = disc.to_vec();
        data.extend_from_slice(&value.to_le_bytes());

        let accounts = vec![
            AccountMeta::new(payer.pubkey(), true),
            AccountMeta::new(data_pda, false),
            AccountMeta::new_readonly(SYSTEM_PROGRAM_ID, false),
        ];

        let ix = Instruction {
            program_id,
            accounts,
            data,
        };

        let recent_blockhash = rpc.get_latest_blockhash().unwrap();
        let tx = Transaction::new_signed_with_payer(
            &[ix],
            Some(&payer.pubkey()),
            &[&payer],
            recent_blockhash,
        );
        rpc.send_and_confirm_transaction(&tx)
            .expect("initialize transaction failed");

        // Fetch and verify the PDA account data
        let account = rpc.get_account(&data_pda).expect("PDA account not found");
        assert_eq!(account.owner, program_id, "PDA owner should be our program");

        // Layout: 8-byte discriminator + 8-byte u64 (value) + 1-byte u8 (bump)
        let account_data = &account.data;
        assert!(
            account_data.len() >= 17,
            "account data too short: {} bytes",
            account_data.len()
        );

        let stored_value = u64::from_le_bytes(account_data[8..16].try_into().unwrap());
        let stored_bump = account_data[16];

        assert_eq!(stored_value, 42, "stored value should be 42");
        assert_eq!(
            stored_bump, expected_bump,
            "stored bump should match the canonical bump"
        );

        println!("all assertions passed: value={stored_value}, bump={stored_bump}");
    }
}
