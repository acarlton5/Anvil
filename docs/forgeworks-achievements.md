# Forgeworks Achievements

This is the local development slice of Forgeworks achievements for Anvil. It is
meant to run on DevBox in Docker while Anvil is still using local cartridge
metadata and OpenGOAL builds.

The service records achievement claims, not final trusted unlocks. That wording
is intentional: the later Forgeworks backend needs proper identity,
entitlements, signed game sessions, replay protection, and verification rules
before achievements should be treated like Steam-style authoritative unlocks.

## Run Locally

```bash
docker compose -f docker-compose.forgeworks.yml up --build
```

The service listens on:

```text
http://devbox.tailb90d48.ts.net:18080
```

## API

Health check:

```bash
curl http://localhost:18080/health
```

List achievement sets:

```bash
curl http://localhost:18080/v1/achievement-sets
```

Read one achievement set:

```bash
curl http://localhost:18080/v1/achievement-sets/jak-and-daxter-ps4
```

Record a local development claim:

```bash
curl -X POST http://localhost:18080/v1/claims \
  -H 'content-type: application/json' \
  -d '{
    "player_id": "local-dev",
    "game_id": "jak-and-daxter-opengoal",
    "achievement_set": "jak-and-daxter-ps4",
    "achievement_id": "precursor_legacy",
    "evidence": {
      "source": "local-dev",
      "note": "manual development claim"
    }
  }'
```

Read player claims:

```bash
curl http://localhost:18080/v1/players/local-dev/achievements
```

Submit a claim through the Anvil helper:

```bash
ANVIL_GAME_ID=jak-and-daxter-opengoal \
ANVIL_ACHIEVEMENT_SET=jak-and-daxter-ps4 \
ANVIL_ACHIEVEMENTS_URL=http://localhost:18080 \
scripts/anvil-achievement-claim precursor_legacy --evidence source=local-test
```

When Anvil launches a game, `anvil-game-session` exports
`ANVIL_GAME_ID`, `ANVIL_ACHIEVEMENT_SET`, `ANVIL_ACHIEVEMENT_SET_FILE`, and
`ANVIL_ACHIEVEMENTS_URL` for game integrations. A Framework Anvil Session can
point at DevBox with:

```bash
ANVIL_ACHIEVEMENTS_URL=http://devbox.tailb90d48.ts.net:18080
```

## Next Contracts

- Add a tiny game-side SDK command that submits signed claims.
- Give each launched game a session token from Anvil Runtime.
- Move claim verification to Forgeworks rules per game and build.
- Keep Constellation underneath identity, entitlement, and delivery instead of
  making Anvil call Constellation APIs directly.
