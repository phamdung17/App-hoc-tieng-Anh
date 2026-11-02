"""app/integrations/mailer/__init__.py"""

from .client import MailerClient
from .errors import MailConfigError, MailSendError

__all__ = ["MailerClient", "MailSendError", "MailConfigError"]
