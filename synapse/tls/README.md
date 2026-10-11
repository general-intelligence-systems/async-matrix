# The federation certificate of the test rig

`federation.pem` is a self-signed certificate and its key, for `localhost`, valid for a century. It
is committed deliberately: the rig is a throwaway with nothing in it worth protecting, and the
alternative is generating one on every run.

It exists because the identity server verifies an OpenID token by asking the homeserver over
federation, which is HTTPS and not negotiable: `use_tls_for_federation` is an argument to Sydent's
constructor rather than a setting, and only its own test harness passes false. So the rig terminates
TLS on 8448 in front of the homeserver, and the identity server is told not to verify the
certificate.
