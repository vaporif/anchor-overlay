use anchor_lang::prelude::*;

declare_id!("GhFvtLtEoY6ZPKGA4S4uWJH3vaJMgBY5aWRLK5XNmEVf");

#[account]
pub struct DataAccount {
    pub value: u64,
    pub bump: u8,
}

#[program]
pub mod my_program {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, value: u64) -> Result<()> {
        let data_account = &mut ctx.accounts.data_account;
        data_account.value = value;
        data_account.bump = ctx.bumps.data_account;
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,
    #[account(
        init,
        payer = signer,
        space = 8 + 8 + 1,
        seeds = [b"data", signer.key().as_ref()],
        bump,
    )]
    pub data_account: Account<'info, DataAccount>,
    pub system_program: Program<'info, System>,
}
