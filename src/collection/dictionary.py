__all__ = ["DotDict"]

from typing import Any


class DotDict(dict):
    """Enabling dot.notation access to dictionary attributes and dynamic code assist in jupyter"""

    _getattr__ = dict.get
    __delattr__ = dict.__delitem__

    def __init__(self, *args, **kwargs) -> None:
        super().__init__()

        for arg in args:
            if isinstance(arg, dict):
                for k, v in arg.items():
                    self[k] = v

        for k, v in kwargs.items():
            self[k] = v

    def __getattr__(self, item) -> Any:  # needed for mypy checks
        if item in self:
            return self._getattr__(item)
        else:
            return getattr(super, item, None)  # try to get the default attribute from Dict

    def __setattr__(self, name: str, value) -> None:
        try:
            getattr(super, name)  # check if name already exists in the default attribute of the Dict
        except AttributeError:
            if isinstance(value, dict):
                value = DotDict(value)
            self[name] = value
        else:
            raise KeyError(f'Name {name} already exists in the default attribute of the dict, use another name.')

    def __setitem__(self, key, value) -> None:
        if isinstance(value, dict):
            value = DotDict(value)
        super().__setitem__(key, value)

    @property
    def __dict__(self):
        return self


