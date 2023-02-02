module resource::pseudo_lp {
    use std::signer::address_of;
    use aptos_framework::aptos_account::transfer;
    use aptos_framework::resource_account::{retrieve_resource_account_cap};
    use aptos_framework::account::{create_signer_with_capability, SignerCapability, new_event_handle};
    use aptos_framework::coin::{BurnCapability, MintCapability, mint, deposit, destroy_freeze_cap, register, burn_from};
    use aptos_framework::coin;
    use std::string;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::event::{EventHandle, emit_event};
    use std::string::String;

    struct LpToken {}
    struct AptUSDC {}

    struct Event has drop, store {
        sender: address,
        amount: u64,
        msg: String
    }

    struct Account has key {
        event_handle: EventHandle<Event>,
    }

    struct Caps has key {
        signer_cap: SignerCapability,
        lp_burn_cap: BurnCapability<LpToken>,
        lp_mint_cap: MintCapability<LpToken>,

        ausdc_burn_cap: BurnCapability<AptUSDC>,
        ausdc_mint_cap: MintCapability<AptUSDC>,
    }


    fun init_module(resource: &signer) {
        let (lp_burn_cap, lp_freeze_cap , lp_mint_cap) =
            coin::initialize<LpToken>(resource, string::utf8(b"lp-token"), string::utf8(b"LP"), 8, true);

        let (ausdc_burn_cap, atusdc_freeze_cap, ausdc_mint_cap) =
            coin::initialize<AptUSDC>(resource, string::utf8(b"apt-usdc"), string::utf8(b"AUSDC"), 8, true);

        let signer_cap = retrieve_resource_account_cap(resource, @admin);

        let caps = Caps {
            signer_cap,
            lp_burn_cap,
            lp_mint_cap,
            ausdc_burn_cap,
            ausdc_mint_cap
        };

        move_to(resource, caps);

        destroy_freeze_cap(lp_freeze_cap);
        destroy_freeze_cap(atusdc_freeze_cap);

        register<LpToken>(resource);
        register<AptUSDC>(resource);

        let event_handle = new_event_handle<Event>(resource);
        move_to(resource, Account {
            event_handle
        })
    }

    public entry fun provide_liquidity(user: &signer, amount: u64) acquires Caps, Account {
        let caps = borrow_global_mut<Caps>(@resource);

        register<LpToken>(user);

        let new_lp_token = mint(amount, &caps.lp_mint_cap);
        deposit<LpToken>(address_of(user), new_lp_token);

        transfer(user, @resource, amount);

        let event_handle = borrow_global_mut<Account>(@resource);
        emit_event(&mut event_handle.event_handle, Event {
            msg: string::utf8(b"provide_liquidity"),
            amount,
            sender: address_of(user)
        })
    }

    public entry fun buy_ausdc(user: &signer, amount: u64) acquires Caps, Account {
        let caps = borrow_global_mut<Caps>(@resource);

        register<AptUSDC>(user);

        let new_ausdc = mint(amount, &caps.ausdc_mint_cap);
        deposit<AptUSDC>(address_of(user), new_ausdc);

        transfer(user, @resource, amount);

        let event_handle = borrow_global_mut<Account>(@resource);
        emit_event(&mut event_handle.event_handle, Event {
            msg: string::utf8(b"buy_ausdc"),
            amount,
            sender: address_of(user)
        })
    }

    public entry fun sell_ausdc(user: &signer, amount: u64) acquires Caps, Account {
        let caps = borrow_global_mut<Caps>(@resource);
        let signer = create_signer_with_capability( &mut caps.signer_cap);

        register<AptosCoin>(user);
        transfer(&signer, address_of(user), amount);

        coin::transfer<AptUSDC>(user, @resource, amount);

        let event_handle = borrow_global_mut<Account>(@resource);
        emit_event(&mut event_handle.event_handle, Event {
            msg: string::utf8(b"sell_ausdc"),
            amount,
            sender: address_of(user)
        })
    }

    public entry fun remove_liquidity(user: &signer, amount: u64) acquires Caps, Account {
        let caps = borrow_global_mut<Caps>(@resource);
        let signer = create_signer_with_capability( &mut caps.signer_cap);

        burn_from(address_of(user), amount, &caps.lp_burn_cap);
        transfer(&signer, address_of(user), amount);

        let event_handle = borrow_global_mut<Account>(@resource);
        emit_event(&mut event_handle.event_handle, Event {
            msg: string::utf8(b"remove_liquidity"),
            amount,
            sender: address_of(user)
        })
    }
}