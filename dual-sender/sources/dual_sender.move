module admin::dual_sender {
    use aptos_framework::coin::transfer;

    public entry fun dual_send<T1, T2>(user: &signer, to: address, amount: u64) {
        transfer<T1>(user, to, amount);
        transfer<T2>(user, to, amount);
    }
}
