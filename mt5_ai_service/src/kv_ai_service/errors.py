class ProviderError(Exception):
    """A provider's raw output could not be turned into a trustworthy SignalResponse."""

    def __init__(self, reason: str, detail: str = ""):
        self.reason = reason
        self.detail = detail
        super().__init__(f"{reason}: {detail}" if detail else reason)
