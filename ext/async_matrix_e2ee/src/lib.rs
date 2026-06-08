//! Ruby bindings for vodozemac (Matrix Olm/Megolm), via magnus.
//!
//! This is the Ruby analogue of matrix-nio/vodozemac-python (which uses PyO3).
//! It exposes vodozemac's Account / Session (Olm) and GroupSession /
//! InboundGroupSession (Megolm) under the `Async::Matrix::E2EE` module.
//!
//! The API is deliberately base64-string / integer centric rather than passing
//! wrapped key objects around: Matrix moves keys and ciphertext as base64
//! strings inside JSON, so a string API drops straight into the protocol layer
//! and keeps the magnus surface small.

use std::cell::RefCell;
use std::collections::HashMap;

use magnus::{function, method, prelude::*, Error, Ruby};

use vodozemac::{base64_decode, base64_encode, Curve25519PublicKey, Ed25519PublicKey, Ed25519Signature};
use vodozemac::olm::{
    Account as OlmAccount, AccountPickle, OlmMessage, PreKeyMessage, Session as OlmSession,
    SessionConfig as OlmSessionConfig, SessionPickle,
};
use vodozemac::megolm::{
    GroupSession as MegolmGroupSession, GroupSessionPickle, InboundGroupSession as MegolmInbound,
    InboundGroupSessionPickle, MegolmMessage, SessionConfig as MegolmSessionConfig, SessionKey,
};

// --- helpers ---------------------------------------------------------------

fn rt_err<E: std::fmt::Display>(e: E) -> Error {
    // Safe: every caller runs inside a Ruby method invocation (GVL held).
    let ruby = Ruby::get().expect("rt_err called outside the Ruby VM");
    Error::new(ruby.exception_runtime_error(), e.to_string())
}

fn key32(label: &str, bytes: &[u8]) -> Result<[u8; 32], Error> {
    bytes
        .try_into()
        .map_err(|_| rt_err(format!("{label} must be 32 bytes, got {}", bytes.len())))
}

// --- Account ---------------------------------------------------------------

#[magnus::wrap(class = "Async::Matrix::E2EE::Account", free_immediately, size)]
struct Account(RefCell<OlmAccount>);

impl Account {
    fn new() -> Self {
        Account(RefCell::new(OlmAccount::new()))
    }

    fn from_pickle(pickle: String, pickle_key: String) -> Result<Self, Error> {
        let key = key32("pickle_key", pickle_key.as_bytes())?;
        let p = AccountPickle::from_encrypted(&pickle, &key).map_err(rt_err)?;
        Ok(Account(RefCell::new(OlmAccount::from_pickle(p))))
    }

    fn pickle(&self, pickle_key: String) -> Result<String, Error> {
        let key = key32("pickle_key", pickle_key.as_bytes())?;
        Ok(self.0.borrow().pickle().encrypt(&key))
    }

    fn ed25519_key(&self) -> String {
        self.0.borrow().ed25519_key().to_base64()
    }

    fn curve25519_key(&self) -> String {
        self.0.borrow().curve25519_key().to_base64()
    }

    fn sign(&self, message: String) -> String {
        self.0.borrow().sign(message.as_bytes()).to_base64()
    }

    fn one_time_keys(&self) -> HashMap<String, String> {
        self.0
            .borrow()
            .one_time_keys()
            .into_iter()
            .map(|(k, v)| (k.to_base64(), v.to_base64()))
            .collect()
    }

    fn max_number_of_one_time_keys(&self) -> usize {
        self.0.borrow().max_number_of_one_time_keys()
    }

    fn generate_one_time_keys(&self, count: usize) {
        self.0.borrow_mut().generate_one_time_keys(count);
    }

    fn fallback_key(&self) -> HashMap<String, String> {
        self.0
            .borrow()
            .fallback_key()
            .into_iter()
            .map(|(k, v)| (k.to_base64(), v.to_base64()))
            .collect()
    }

    fn generate_fallback_key(&self) {
        self.0.borrow_mut().generate_fallback_key();
    }

    fn mark_keys_as_published(&self) {
        self.0.borrow_mut().mark_keys_as_published();
    }

    /// Returns a Session for sending to a peer identified by their identity and
    /// one-time keys (both base64).
    fn create_outbound_session(
        &self,
        identity_key: String,
        one_time_key: String,
    ) -> Result<Session, Error> {
        let ik = Curve25519PublicKey::from_base64(&identity_key).map_err(rt_err)?;
        let otk = Curve25519PublicKey::from_base64(&one_time_key).map_err(rt_err)?;
        let session = self
            .0
            .borrow()
            .create_outbound_session(OlmSessionConfig::version_1(), ik, otk)
            .map_err(rt_err)?;
        Ok(Session(RefCell::new(session)))
    }

    /// Establishes an inbound Session from a received pre-key message (base64
    /// body, as carried in an m.room.encrypted olm `body`). Returns
    /// `[session, plaintext]`.
    fn create_inbound_session(
        &self,
        identity_key: String,
        prekey_message_body: String,
    ) -> Result<(Session, String), Error> {
        let ik = Curve25519PublicKey::from_base64(&identity_key).map_err(rt_err)?;
        let prekey = PreKeyMessage::from_base64(&prekey_message_body).map_err(rt_err)?;
        let result = self
            .0
            .borrow_mut()
            .create_inbound_session(OlmSessionConfig::version_1(), ik, &prekey)
            .map_err(rt_err)?;
        let plaintext = String::from_utf8(result.plaintext).map_err(rt_err)?;
        Ok((Session(RefCell::new(result.session)), plaintext))
    }
}

// --- Session (Olm 1:1) -----------------------------------------------------

#[magnus::wrap(class = "Async::Matrix::E2EE::Session", free_immediately, size)]
struct Session(RefCell<OlmSession>);

impl Session {
    fn session_id(&self) -> String {
        self.0.borrow().session_id()
    }

    fn pickle(&self, pickle_key: String) -> Result<String, Error> {
        let key = key32("pickle_key", pickle_key.as_bytes())?;
        Ok(self.0.borrow().pickle().encrypt(&key))
    }

    fn from_pickle(pickle: String, pickle_key: String) -> Result<Self, Error> {
        let key = key32("pickle_key", pickle_key.as_bytes())?;
        let p = SessionPickle::from_encrypted(&pickle, &key).map_err(rt_err)?;
        Ok(Session(RefCell::new(OlmSession::from_pickle(p))))
    }

    /// Encrypts plaintext; returns `[message_type, body_base64]` matching the
    /// Matrix olm ciphertext shape.
    fn encrypt(&self, plaintext: String) -> Result<(usize, String), Error> {
        let message = self.0.borrow_mut().encrypt(plaintext.as_bytes()).map_err(rt_err)?;
        let (mtype, ciphertext) = message.to_parts();
        Ok((mtype, base64_encode(ciphertext)))
    }

    /// Decrypts an olm message given its type (0 = pre-key, 1 = normal) and
    /// base64 body.
    fn decrypt(&self, message_type: usize, body: String) -> Result<String, Error> {
        let ciphertext = base64_decode(&body).map_err(rt_err)?;
        let message = OlmMessage::from_parts(message_type, &ciphertext).map_err(rt_err)?;
        let plaintext = self.0.borrow_mut().decrypt(&message).map_err(rt_err)?;
        String::from_utf8(plaintext).map_err(rt_err)
    }
}

// --- GroupSession (Megolm outbound) ---------------------------------------

#[magnus::wrap(class = "Async::Matrix::E2EE::GroupSession", free_immediately, size)]
struct GroupSession(RefCell<MegolmGroupSession>);

impl GroupSession {
    fn new() -> Self {
        GroupSession(RefCell::new(MegolmGroupSession::new(MegolmSessionConfig::version_1())))
    }

    fn session_id(&self) -> String {
        self.0.borrow().session_id()
    }

    fn message_index(&self) -> u32 {
        self.0.borrow().message_index()
    }

    /// The session key (base64) to share with recipients via m.room_key.
    fn session_key(&self) -> String {
        self.0.borrow().session_key().to_base64()
    }

    /// Encrypts plaintext, returning the megolm message as base64.
    fn encrypt(&self, plaintext: String) -> String {
        self.0.borrow_mut().encrypt(plaintext.as_bytes()).to_base64()
    }

    fn pickle(&self, pickle_key: String) -> Result<String, Error> {
        let key = key32("pickle_key", pickle_key.as_bytes())?;
        Ok(self.0.borrow().pickle().encrypt(&key))
    }

    fn from_pickle(pickle: String, pickle_key: String) -> Result<Self, Error> {
        let key = key32("pickle_key", pickle_key.as_bytes())?;
        let p = GroupSessionPickle::from_encrypted(&pickle, &key).map_err(rt_err)?;
        Ok(GroupSession(RefCell::new(MegolmGroupSession::from_pickle(p))))
    }
}

// --- InboundGroupSession (Megolm inbound) ---------------------------------

#[magnus::wrap(class = "Async::Matrix::E2EE::InboundGroupSession", free_immediately, size)]
struct InboundGroupSession(RefCell<MegolmInbound>);

impl InboundGroupSession {
    /// Build from a base64 session key received in an m.room_key event.
    fn new(session_key: String) -> Result<Self, Error> {
        let key = SessionKey::from_base64(&session_key).map_err(rt_err)?;
        Ok(InboundGroupSession(RefCell::new(MegolmInbound::new(
            &key,
            MegolmSessionConfig::version_1(),
        ))))
    }

    fn session_id(&self) -> String {
        self.0.borrow().session_id()
    }

    fn first_known_index(&self) -> u32 {
        self.0.borrow().first_known_index()
    }

    /// Decrypts a base64 megolm message; returns `[plaintext, message_index]`.
    fn decrypt(&self, message: String) -> Result<(String, u32), Error> {
        let msg = MegolmMessage::from_base64(&message).map_err(rt_err)?;
        let decrypted = self.0.borrow_mut().decrypt(&msg).map_err(rt_err)?;
        let plaintext = String::from_utf8(decrypted.plaintext).map_err(rt_err)?;
        Ok((plaintext, decrypted.message_index))
    }

    fn pickle(&self, pickle_key: String) -> Result<String, Error> {
        let key = key32("pickle_key", pickle_key.as_bytes())?;
        Ok(self.0.borrow().pickle().encrypt(&key))
    }

    fn from_pickle(pickle: String, pickle_key: String) -> Result<Self, Error> {
        let key = key32("pickle_key", pickle_key.as_bytes())?;
        let p = InboundGroupSessionPickle::from_encrypted(&pickle, &key).map_err(rt_err)?;
        Ok(InboundGroupSession(RefCell::new(MegolmInbound::from_pickle(p))))
    }
}

// --- module-level functions ------------------------------------------------

/// Verify an ed25519 signature. `key` and `signature` are base64; returns bool.
fn verify_signature(key: String, message: String, signature: String) -> Result<bool, Error> {
    let public_key = Ed25519PublicKey::from_base64(&key).map_err(rt_err)?;
    let sig = Ed25519Signature::from_base64(&signature).map_err(rt_err)?;
    Ok(public_key.verify(message.as_bytes(), &sig).is_ok())
}

// --- init ------------------------------------------------------------------

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let namespace = ruby.define_module("Async")?.define_module("Matrix")?.define_module("E2EE")?;

    let account = namespace.define_class("Account", ruby.class_object())?;
    account.define_singleton_method("new", function!(Account::new, 0))?;
    account.define_singleton_method("from_pickle", function!(Account::from_pickle, 2))?;
    account.define_method("pickle", method!(Account::pickle, 1))?;
    account.define_method("ed25519_key", method!(Account::ed25519_key, 0))?;
    account.define_method("curve25519_key", method!(Account::curve25519_key, 0))?;
    account.define_method("sign", method!(Account::sign, 1))?;
    account.define_method("one_time_keys", method!(Account::one_time_keys, 0))?;
    account.define_method(
        "max_number_of_one_time_keys",
        method!(Account::max_number_of_one_time_keys, 0),
    )?;
    account.define_method("generate_one_time_keys", method!(Account::generate_one_time_keys, 1))?;
    account.define_method("fallback_key", method!(Account::fallback_key, 0))?;
    account.define_method("generate_fallback_key", method!(Account::generate_fallback_key, 0))?;
    account.define_method("mark_keys_as_published", method!(Account::mark_keys_as_published, 0))?;
    account.define_method("create_outbound_session", method!(Account::create_outbound_session, 2))?;
    account.define_method("create_inbound_session", method!(Account::create_inbound_session, 2))?;

    let session = namespace.define_class("Session", ruby.class_object())?;
    session.define_singleton_method("from_pickle", function!(Session::from_pickle, 2))?;
    session.define_method("session_id", method!(Session::session_id, 0))?;
    session.define_method("pickle", method!(Session::pickle, 1))?;
    session.define_method("encrypt", method!(Session::encrypt, 1))?;
    session.define_method("decrypt", method!(Session::decrypt, 2))?;

    let group = namespace.define_class("GroupSession", ruby.class_object())?;
    group.define_singleton_method("new", function!(GroupSession::new, 0))?;
    group.define_singleton_method("from_pickle", function!(GroupSession::from_pickle, 2))?;
    group.define_method("session_id", method!(GroupSession::session_id, 0))?;
    group.define_method("message_index", method!(GroupSession::message_index, 0))?;
    group.define_method("session_key", method!(GroupSession::session_key, 0))?;
    group.define_method("encrypt", method!(GroupSession::encrypt, 1))?;
    group.define_method("pickle", method!(GroupSession::pickle, 1))?;

    let inbound = namespace.define_class("InboundGroupSession", ruby.class_object())?;
    inbound.define_singleton_method("new", function!(InboundGroupSession::new, 1))?;
    inbound.define_singleton_method("from_pickle", function!(InboundGroupSession::from_pickle, 2))?;
    inbound.define_method("session_id", method!(InboundGroupSession::session_id, 0))?;
    inbound.define_method("first_known_index", method!(InboundGroupSession::first_known_index, 0))?;
    inbound.define_method("decrypt", method!(InboundGroupSession::decrypt, 1))?;
    inbound.define_method("pickle", method!(InboundGroupSession::pickle, 1))?;

    namespace.define_module_function("verify_signature", function!(verify_signature, 3))?;

    Ok(())
}
