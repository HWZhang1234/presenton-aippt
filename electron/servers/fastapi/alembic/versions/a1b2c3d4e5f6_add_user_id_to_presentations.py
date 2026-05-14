"""add user_id to presentations

Revision ID: a1b2c3d4e5f6
Revises: 82abdbc476a7
Create Date: 2026-05-12 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = '95b5127e93cd'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('presentations', sa.Column('user_id', sa.String(), nullable=True))
    op.create_index('ix_presentations_user_id', 'presentations', ['user_id'])


def downgrade() -> None:
    op.drop_index('ix_presentations_user_id', table_name='presentations')
    op.drop_column('presentations', 'user_id')
