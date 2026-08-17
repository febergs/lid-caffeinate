# lid-caffeinate ☕

![platform](https://img.shields.io/badge/platform-macOS-000000?logo=apple) ![license](https://img.shields.io/badge/license-MIT-blue)

Keep your Mac awake **with the lid closed** — for a fixed number of minutes, then everything goes back to normal on its own.

`caffeinate` is great until you close the lid. `lid-caffeinate` flips the one `pmset` flag that keeps a closed-lid Mac awake, babysits a timer, and — the important part — **always puts it back**: timer done, battery low, or Ctrl+C.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/febergs/lid-caffeinate/main/install.sh | bash
```

Or from a checkout: `./install.sh`. Lands in the first writable dir of `/usr/local/bin`, `/opt/homebrew/bin`, or `~/.local/bin`.

## Usage

```console
$ lid-caffeinate          # awake (lid closed OK) for 60 min — the default
🔥 lid-caffeinate: staying awake WITH LID CLOSED for 60 min (until 14:35)
   Battery now: 76%  |  will bail early at 20%
   Close the lid whenever. Ctrl+C = end early (safely restores).
```

```bash
lid-caffeinate 30         # 30 minutes (max 240)
lid-caffeinate --help
```

Close the lid whenever. Done? The lid sleeps normally again — no lingering settings, no mystery bag-warm Mac.

## Failsafes

- Auto-restores when the timer expires
- Auto-restores early at ≤ 20% battery (**only while on battery** — plugged in at 19% and charging is fine)
- Ctrl+C restores immediately
- Refuses runs longer than 240 min
- Paranoia button: `sudo pmset -a disablesleep 0` restores normal sleep manually

## How it works

One flag: [`pmset disablesleep`](https://keith.github.io/xcode-man-pages/pmset.1.html). While the timer runs, it's set to `1` on both battery and charger profiles; a trap guarantees it's set back to `0` on any exit path. No daemons, no launchd, ~100 lines of bash. Requires sudo (the `pmset` flag is root-only), so it runs via sudo when needed.

## Uninstall

```bash
sudo rm /usr/local/bin/lid-caffeinate   # or wherever it landed
```

## License

[MIT](LICENSE)
