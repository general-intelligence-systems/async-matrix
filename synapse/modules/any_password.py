# Accepts any password for any user, registering the user on first login.
#
# Synapse has no way to turn password checking off, so this is the smallest
# module that does it. It means no user setup at all: log in as anyone, with
# anything, and the account appears.
#
# This is a throwaway local rig with nothing in it worth protecting. Never
# point it at a reachable interface.


class AnyPasswordAuthProvider:
    def __init__(self, config, api):
        self._api = api
        api.register_password_auth_provider_callbacks(
            auth_checkers={("m.login.password", ("password",)): self.check_password},
        )

    @staticmethod
    def parse_config(config):
        return config

    async def check_password(self, username, login_type, login_dict):
        # username may be a localpart or a full @user:server.
        localpart = username.split(":")[0].lstrip("@")
        user_id = self._api.get_qualified_user_id(localpart)

        if not await self._api.check_user_exists(user_id):
            await self._api.register_user(localpart)

        return (user_id, None)
