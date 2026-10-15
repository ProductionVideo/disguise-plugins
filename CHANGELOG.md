# Changelog

## 1.1.0

- Projector Monitor: Epson support (ESC/VP21 over the HTTP control API with Digest authentication) for power, shutter, input, signal, fault, freeze, serial and light-source hours. Choose the brand per projector; existing configurations load as Panasonic.
- Projector Monitor: Very compact size; buttons highlight the projector's current state; coloured state edge and brand on each card; fixed card heights so Designer's window fits exactly at every size; errors shown in the card footer without changing card height; Readings renamed Status and refreshes while open; NRMW footer label removed.
- All plugins: helpers stop when the Designer that started them exits. Start replaces leftover or unresponsive helpers and confirms the new one is answering; Stop ends an unresponsive helper. World Clock's unused duplicate `Start-Native.ps1` is removed.
- Projector Monitor: protocol code split into per-brand drivers; slot state is passed directly instead of being swapped through script globals; remembered control request IDs are capped; blank IPs are validated without a placeholder address; the readings dialog hides values a brand does not report; window-fit replies are returned as JSON.

## 1.0.0

- Device Monitor: configurable devices, concurrent ping checks, compact cards and shared size widths.
- Projector Monitor: up to 12 projectors, saved credentials, power/shutter controls, readings and configurable layouts.
- World Clock: up to 8 saved timezones, three sizes, minute precision and NRMW branding.
- Videohub Monitor: saved endpoint, visible-port filters, automatic sizing, transposed orientation, batch Take, click-to-unselect and confirmed routing feedback.
- Portable local defaults, individual install guides, and configurable shared hosting without show-specific addresses.
