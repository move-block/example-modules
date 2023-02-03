module bank_resource::bank {

    use std::string::String;
    use aptos_framework::event::{EventHandle, emit_event};
    use std::string;
    use std::signer::address_of;
    use aptos_framework::coin::transfer;
    use aptos_framework::account::{SignerCapability, new_event_handle, create_signer_with_capability};
    use aptos_framework::resource_account::retrieve_resource_account_cap;

    struct Event has drop, store {
        sender: address,
        amount: u64,
        msg: String
    }

    struct Account has key {
        signer_cap: SignerCapability,
        event_handle: EventHandle<Event>,
    }

    fun init_module(resource: &signer) {
        let signer_cap = retrieve_resource_account_cap(resource, @bank_admin);

        let event_handle = new_event_handle<Event>(resource);
        move_to(resource, Account {
            signer_cap,
            event_handle
        })
    }


    public entry fun borrow<T>(resource: &signer, amount: u64) acquires Account {
        let account_res = borrow_global_mut<Account>(@bank_resource);
        let signer = create_signer_with_capability( &mut account_res.signer_cap);

        transfer<T>(&signer, address_of(resource), amount);
        let msg = string::utf8(b"borrow coin from bank");
        emit_event(&mut account_res.event_handle, Event {
            sender: @bank_resource,
            amount,
            msg
        })
    }

    public entry fun repay<T>(user: &signer, amount: u64) acquires Account {
        transfer<T>(user, @bank_resource, amount);
        let event_handle = borrow_global_mut<Account>(@bank_resource);
        let msg = string::utf8(b"pay off coin to bank");
        emit_event(&mut event_handle.event_handle, Event {
            sender: address_of(user),
            amount,
            msg
        })
    }
}
