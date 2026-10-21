# System trust store hardening.
{ ... }:
{
  flake.aspects.security = {
    nixos =
      { ... }:
      {
        # emSign / eMudhra incident (disclosed 2026-10-17): the private keys of
        # eight eMudhra intermediate CAs were generated with weak entropy and are
        # recoverable from the certificates, so anyone can mint a certificate for
        # any domain that chains to a trusted root. Browsers blocked them via
        # revocation data (CRLSets / OneCRL), but OpenSSL-based clients never
        # consult that: for them only the roots in nss-cacert matter.
        #
        # `emSign ECC Root CA - G3` signed the compromised intermediates;
        # `Comodo AAA Services root` is the Sectigo cross-sign of the same keys.
        # nss-cacert 3.126 (the pin at the time of writing) still trusts both.
        #
        # Drop this once nixpkgs ships nss-cacert >= 3.131.1, which removes the
        # G3 root outright.
        security.pki.caCertificateBlacklist = [
          "Comodo AAA Services root"
          "emSign ECC Root CA - G3"
        ];
      };
  };
}
