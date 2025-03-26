from typing import Optional

class VpnUser:
    def __init__(self, username: str, traffic_limit: int, expiration_days: int, password: Optional[str] = None):
        """
        Initialize a VPN user.
        
        Args:
            username: User's username
            traffic_limit: Traffic limit in GB
            expiration_days: Number of days until expiration
            password: Optional password for the user
        """
        self.username = username
        # API accepts GB directly so no conversion needed
        self.traffic_limit = traffic_limit
        self.expiration_days = expiration_days
        self.password = password
