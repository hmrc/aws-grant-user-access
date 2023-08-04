version: 0.2

env:
  shell: bash
  parameter-store:
    LABS_ACCOUNT_ID: "/labs/account_id"
    LIVE_ACCOUNT_ID: "/live/account_id"

phases:
  build:
    commands:
      - ./scripts/apply.sh ${target}
