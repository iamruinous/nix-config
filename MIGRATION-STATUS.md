# Agenix-Rekey Migration Status

## ✅ Completed

1. **Master age key created**
   - Private: `secrets/master-keys/master.age`
   - Public: `age17tu85cfnjkqcx9u458qfedrj88credzqpa44hs9lzklhg5m8kaesrqsxfd`
   - ⚠️ **BACKUP THE PRIVATE KEY NOW!**

2. **Flake.nix updated** with agenix-rekey input and configuration

3. **Host SSH keys configured** (9 of 12 hosts):
   - ✅ framework, monolith, obelisk, pilaster, tty-ruinous-social (NixOS)
   - ✅ jmacmini, studio, jbookpro (macOS)
   - ✅ ruinous-tty, messy-tty (NixOS)
   - ❌ gap, void (need keys)

4. **46 secret declarations converted** from `file =` to `rekeyFile =`

5. **.gitignore updated** to exclude `secrets/master-keys/*.age` and `secrets/rekeyed/`

## ⚠️ Current Issue

The agenix-rekey module configuration is encountering a module system evaluation error where `age.rekey.storageMode` isn't being recognized despite being set. This appears to be a module ordering or structure issue with how agenix-rekey validates its configuration.

## 🔧 Workaround: Manual Per-Host Configuration

Instead of using a shared module, we can configure each host individually. This is more explicit and avoids module evaluation order issues.

### Example for hosts/framework/configuration.nix:

```nix
{
  imports = [
    # ... existing imports ...
  ];

  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8xqxaR93hZCPoHmuZDi3NrIF/JD/1nFG4rV7O7iR26";
    masterIdentities = [{
      type = "age";
      pubkey = "age17tu85cfnjkqcx9u458qfedrj88credzqpa44hs9lzklhg5m8kaesrqsxfd";
    }];
    storageMode = "local";
    localStorageDir = ../../. + "/secrets/rekeyed/framework";
    agePlugins = ["ssh-ed25519"];
  };
}
```

## 📋 Next Steps

1. **Option A: Add per-host configuration** (recommended for now)
   - Add `age.rekey` block to each host's configuration.nix
   - Test with one host first (framework)
   - Run rekey: `AGE_IDENTITY_FILE=secrets/master-keys/master.age nix run .#agenix-rekey.x86_64-darwin.rekey -- -h framework`

2. **Option B: Debug module system issue**
   - Review agenix-rekey documentation for module examples
   - Check if there's a specific import order required
   - Consider filing an issue with agenix-rekey project

3. **After successful rekey:**
   - Delete `secrets/secrets.nix`
   - Commit all changes
   - Deploy to all hosts

## 🎯 Migration Benefits (Once Complete)

- No more `secrets.nix` maintenance
- Master key security model
- Automatic rekeying workflow
- Easier host onboarding

## 📝 Reference

**Master Public Key:** `age17tu85cfnjkqcx9u458qfedrj88credzqpa44hs9lzklhg5m8kaesrqsxfd`

**Host Keys:** See `secrets/secrets.nix` for current SSH public keys

**Rekey Command:**
```bash
AGE_IDENTITY_FILE=secrets/master-keys/master.age \
  nix run .#agenix-rekey.x86_64-darwin.rekey -- --all
```
