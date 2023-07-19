version: 0.2

env:
  shell: bash

phases:
  build:
    commands:
      - ./scripts/apply.sh ${target}
