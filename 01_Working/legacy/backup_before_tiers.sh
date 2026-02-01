#!/bin/bash
# ============================================================================
# EQEmu Database Backup Script - Before Tier Generation
# ============================================================================
# Usage: ./backup_before_tiers.sh
# This will create timestamped backups in /opt/akk-stack/backups/
# ============================================================================

BACKUP_DIR="/opt/akk-stack/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME="eqemu"
DB_USER="root"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "============================================================================"
echo "EQEmu Database Backup - Before Tier Generation"
echo "============================================================================"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}Starting backup process...${NC}"
echo ""

# Option 1: Full database backup (compressed)
echo -e "${GREEN}[1/3] Creating full database backup (compressed)...${NC}"
mysqldump -u "$DB_USER" -p "$DB_NAME" | gzip > "$BACKUP_DIR/eqemu_full_${TIMESTAMP}.sql.gz"

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$BACKUP_DIR/eqemu_full_${TIMESTAMP}.sql.gz" | cut -f1)
    echo -e "${GREEN}✓ Full backup created: eqemu_full_${TIMESTAMP}.sql.gz (${SIZE})${NC}"
else
    echo -e "${RED}✗ Full backup failed!${NC}"
    exit 1
fi

echo ""

# Option 2: Items table only (uncompressed for quick restore)
echo -e "${GREEN}[2/3] Creating items table backup...${NC}"
mysqldump -u "$DB_USER" -p "$DB_NAME" items > "$BACKUP_DIR/items_only_${TIMESTAMP}.sql"

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$BACKUP_DIR/items_only_${TIMESTAMP}.sql" | cut -f1)
    echo -e "${GREEN}✓ Items backup created: items_only_${TIMESTAMP}.sql (${SIZE})${NC}"
else
    echo -e "${RED}✗ Items backup failed!${NC}"
    exit 1
fi

echo ""

# Option 3: Create backup table in database (fastest rollback)
echo -e "${GREEN}[3/3] Creating in-database backup table...${NC}"
mysql -u "$DB_USER" -p "$DB_NAME" <<EOF
DROP TABLE IF EXISTS items_backup_${TIMESTAMP};
CREATE TABLE items_backup_${TIMESTAMP} LIKE items;
INSERT INTO items_backup_${TIMESTAMP} SELECT * FROM items;
SELECT CONCAT('✓ Backup table created: items_backup_${TIMESTAMP} with ', COUNT(*), ' items') AS status FROM items_backup_${TIMESTAMP};
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ In-database backup table created${NC}"
else
    echo -e "${RED}✗ In-database backup failed!${NC}"
fi

echo ""
echo "============================================================================"
echo -e "${GREEN}BACKUP COMPLETE${NC}"
echo "============================================================================"
echo ""
echo "Backup files created:"
echo "  1. Full DB: $BACKUP_DIR/eqemu_full_${TIMESTAMP}.sql.gz"
echo "  2. Items only: $BACKUP_DIR/items_only_${TIMESTAMP}.sql"
echo "  3. In-DB table: items_backup_${TIMESTAMP}"
echo ""
echo "To restore from backup:"
echo "  Full DB:    gunzip < eqemu_full_${TIMESTAMP}.sql.gz | mysql -u root -p eqemu"
echo "  Items only: mysql -u root -p eqemu < items_only_${TIMESTAMP}.sql"
echo "  In-DB:      TRUNCATE items; INSERT INTO items SELECT * FROM items_backup_${TIMESTAMP};"
echo ""
echo -e "${YELLOW}You can now safely run the tier generation script.${NC}"
echo "============================================================================"
