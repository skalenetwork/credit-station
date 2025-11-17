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

from eth_typing import HexStr
from pydantic_settings import BaseSettings, SettingsConfigDict
from skale.types.schain import SchainName


class Config(BaseSettings):
    mainnet_endpoint: str
    schain_endpoint: str

    mainnet_contracts: str
    schain_contracts: str

    schain_name: SchainName

    from_block: int
    eth_private_key: HexStr

    state_file: str = 'state.json'

    agent_loop_sleep: int = 120
    agent_exception_sleep: int = 10

    payment_value_eth: int = 1
    payment_value_wei: int = payment_value_eth * 10**18

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        case_sensitive=False,
        extra='ignore',
    )


def get_config() -> Config:
    return Config()  # type: ignore[call-arg]
