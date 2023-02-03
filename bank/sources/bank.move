module bank_resource::bank {

    use std::string::String;
    use aptos_framework::event::{EventHandle, emit_event};
    use std::string;
    use std::signer::address_of;
    use aptos_framework::coin::transfer;

    struct Event has drop, store {
        sender: address,
        amount: u64,
        msg: String
    }

    struct Account has key {
        event_handle: EventHandle<Event>,
    }


    public entry fun borrow<T>(_: &signer, amount: u64) acquires Account {
        let event_handle = borrow_global_mut<Account>(@bank_resource);
        let msg = string::utf8(b"borrow coin from bank");
        emit_event(&mut event_handle.event_handle, Event {
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
