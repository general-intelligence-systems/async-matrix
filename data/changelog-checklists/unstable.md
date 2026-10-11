# Matrix Specification Changes since last release


## Client-Server API

**Breaking Changes**

- [ ] Clients are now supposed to follow 30x redirects from `/.well-known/matrix/client` as per [MSC4402](https://github.com/matrix-org/matrix-spec-proposals/pull/4402). ([#2404](https://github.com/matrix-org/matrix-spec/issues/2404))
- [ ] Providing access tokens via query string parameters is no longer supported. ([#2408](https://github.com/matrix-org/matrix-spec/issues/2408))

**Backwards Compatible Changes**

- [ ] Introduce room type `m.policy` to indicate rooms likely to contain policy lists, as per [MSC3784](https://github.com/matrix-org/matrix-spec-proposals/pull/3784). ([#2411](https://github.com/matrix-org/matrix-spec/issues/2411))
- [ ] Specify `unsigned.prev_sender` in client-formatted events. Contributed by @timedoutuk. ([#2427](https://github.com/matrix-org/matrix-spec/issues/2427))
- [ ] Introduce module "Media preview configuration", as per [MSC4278](https://github.com/matrix-org/matrix-spec-proposals/pull/4278). ([#2440](https://github.com/matrix-org/matrix-spec/issues/2440))

**Spec Clarifications**

- [ ] Correct some errors in the description of the validation process for incoming Olm-encrypted messages. ([#2394](https://github.com/matrix-org/matrix-spec/issues/2394))
- [ ] Add further normative language in mutual rooms server behaviour. ([#2407](https://github.com/matrix-org/matrix-spec/issues/2407))
- [ ] Use the User ID type in OlmPayload and DeviceKeys. ([#2412](https://github.com/matrix-org/matrix-spec/issues/2412))
- [ ] Improve the format description of `m.room.encrypted` (Olm/Megolm) events. ([#2413](https://github.com/matrix-org/matrix-spec/issues/2413))
- [ ] Wording improvements and spelling fixes. Contributed by @HarHarLinks. ([#2417](https://github.com/matrix-org/matrix-spec/issues/2417))
- [ ] Rename OlmPayload to OlmPlaintext to avoid confusion with Olm message Payload Bytes. ([#2418](https://github.com/matrix-org/matrix-spec/issues/2418))
- [ ] Use MXC URI type for all user `avatar_url` fields. Contributed by @networkException. ([#2422](https://github.com/matrix-org/matrix-spec/issues/2422))
- [ ] Add cross-references between the OpenID endpoints of the Client-Server API, Server-Server API and Identity-Service API. ([#2426](https://github.com/matrix-org/matrix-spec/issues/2426))
- [ ] Disambiguate parts of the UIA specification. ([#2428](https://github.com/matrix-org/matrix-spec/issues/2428))
- [ ] Restore the legacy singular anchor for the well-known URI section. ([#2429](https://github.com/matrix-org/matrix-spec/issues/2429), [#2433](https://github.com/matrix-org/matrix-spec/issues/2433))
- [ ] Link to the relevant OAuth 2.0 RFCs for the structure of error responses on the OAuth 2.0 API endpoints. ([#2432](https://github.com/matrix-org/matrix-spec/issues/2432))
- [ ] Update community-provided translations for SAS Emojis. ([#2438](https://github.com/matrix-org/matrix-spec/issues/2438))


## Server-Server API

**Spec Clarifications**

- [ ] Add cross-references between the OpenID endpoints of the Client-Server API, Server-Server API and Identity-Service API. ([#2426](https://github.com/matrix-org/matrix-spec/issues/2426))
- [ ] Fix the name of the `sig` parameter in the `X-Matrix` `Authorization` header. ([#2450](https://github.com/matrix-org/matrix-spec/issues/2450))


## Application Service API

**Spec Clarifications**

- [ ] Fix various typos throughout the specification. ([#2435](https://github.com/matrix-org/matrix-spec/issues/2435))


## Identity Service API

**Breaking Changes**

- [ ] Providing access tokens via query string parameters is no longer supported. ([#2408](https://github.com/matrix-org/matrix-spec/issues/2408))

**Spec Clarifications**

- [ ] Add cross-references between the OpenID endpoints of the Client-Server API, Server-Server API and Identity-Service API. ([#2426](https://github.com/matrix-org/matrix-spec/issues/2426))


## Push Gateway API

No significant changes.


## Room Versions

No significant changes.


## Olm & Megolm

**Spec Clarifications**

- [ ] Fix typesetting of some symbols in the Olm/Megolm spec. ([#2421](https://github.com/matrix-org/matrix-spec/issues/2421))


## Appendices

**Spec Clarifications**

- [ ] Clarify that clients must avoid producing ambiguous matrix.to URIs. Contributed by @HarHarLinks. ([#2396](https://github.com/matrix-org/matrix-spec/issues/2396))


## Internal Changes/Tooling

**Spec Clarifications**

- [ ] Fix incorrect unstable prefix example for error codes. ([#2446](https://github.com/matrix-org/matrix-spec/issues/2446))

