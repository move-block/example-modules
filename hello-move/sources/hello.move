module admin::hello {
    use aptos_framework::event::{emit_event, EventHandle};
    use std::string::String;
    use aptos_framework::account::new_event_handle;
    use std::string;

    struct Event has drop, store {
        msg: String
    }

    struct Account has key {
        event_handle: EventHandle<Event>
    }

    fun init_module(admin: &signer) {
        let event_handle = new_event_handle<Event>(admin);
        move_to(admin, Account {
            event_handle
        })
    }

    public entry fun hello(_: &signer) acquires Account {
        let event_handle = borrow_global_mut<Account>(@admin);
        let msg = string::utf8(b"hello move block!");
        emit_event(&mut event_handle.event_handle, Event {
            msg
        })
    }

    public entry fun bye(_: &signer) acquires Account {
        let event_handle = borrow_global_mut<Account>(@admin);
        let msg = string::utf8(b"bye move block!");
        emit_event(&mut event_handle.event_handle, Event {
            msg
        })
    }
}
