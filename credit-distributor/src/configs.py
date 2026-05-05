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

# cspell:words customise

import os

from eth_typing import HexStr
from pydantic import BaseModel
from pydantic_settings import (
    BaseSettings,
    PydanticBaseSettingsSource,
    SettingsConfigDict,
    TomlConfigSettingsSource,
)
from skale_core.types import SchainName

CONFIG_FILEPATH = os.path.join(os.path.dirname(__file__), os.pardir, 'config.toml')


class Source(BaseModel):
    name: str
    endpoint: str
    contract: str
    from_block: int
    source_id: int | None = None


class Destination(BaseModel):
    endpoint: str
    contract: str


class Agent(BaseModel):
    loop_sleep: int = 120
    exception_sleep: int = 10
    events_chunk_size: int = 2000


class General(BaseModel):
    schain_name: SchainName
    eth_private_key: HexStr
    state_file: str = 'state.json'


class Config(BaseSettings):
    model_config = SettingsConfigDict(toml_file=CONFIG_FILEPATH)

    general: General
    destination: Destination
    sources: list[Source]
    agent: Agent = Agent()

    @classmethod
    def settings_customise_sources(
        cls,
        settings_cls: type[BaseSettings],
        init_settings: PydanticBaseSettingsSource,
        env_settings: PydanticBaseSettingsSource,
        dotenv_settings: PydanticBaseSettingsSource,
        file_secret_settings: PydanticBaseSettingsSource,
    ) -> tuple[PydanticBaseSettingsSource, ...]:
        return (TomlConfigSettingsSource(settings_cls),)


def get_config() -> Config:
    return Config()  # type: ignore[call-arg]
