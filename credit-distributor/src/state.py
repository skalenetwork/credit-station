#   -*- coding: utf-8 -*-
#
#   This file is part of credit-distributor.
#
#   Copyright (C) 2025 SKALE Labs
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

import json
import logging
from pathlib import Path

from pydantic import BaseModel

logger = logging.getLogger(__name__)


class State(BaseModel):
    from_blocks: dict[str, int]


class StateManager:
    def __init__(self, state_file: str | Path):
        self.state_file = Path(state_file)

    def load(self, initial_from_blocks: dict[str, int]) -> State:
        if self.state_file.exists():
            try:
                stored = State(**json.loads(self.state_file.read_text())).from_blocks
                logger.info(f'Loaded state from {self.state_file}')
                from_blocks = {n: stored.get(n, b) for n, b in initial_from_blocks.items()}
                return State(from_blocks=from_blocks)
            except Exception as e:
                logger.warning(
                    f'Failed to load state from {self.state_file}: {e}. Using initial values.'
                )
        logger.info(f'Creating new state with from_blocks={initial_from_blocks}')
        return State(from_blocks=dict(initial_from_blocks))

    def save(self, state: State) -> None:
        self.state_file.write_text(state.model_dump_json(indent=2))
