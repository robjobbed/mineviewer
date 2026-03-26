---
name: New Miner Driver Request
about: Request support for a new miner type
title: "[Driver] "
labels: new-driver
assignees: ''
---

## Miner Details

- **Manufacturer**: (e.g., MicroBT, Bitmain, Canaan)
- **Model**: (e.g., Whatsminer M50S)
- **Firmware**: (e.g., stock, Braiins OS, custom)

## API Information

How does this miner expose its status and controls? Check all that apply:

- [ ] HTTP REST API
- [ ] CGMiner-compatible API (port 4028)
- [ ] BMMiner API
- [ ] Braiins OS gRPC
- [ ] SSH / command-line
- [ ] Other (describe below)

## API Documentation

Link to any API documentation, firmware docs, or reverse-engineering notes. If no public docs exist, describe what you know about the miner's API endpoints and data format.

## Do You Have Access to This Hardware?

- [ ] Yes, I can test a driver implementation
- [ ] No, I am requesting this for future use

## Additional Context

Any other details -- firmware version quirks, known API limitations, or related projects that have implemented support for this miner.
