const fs = require('node:fs');
const path = require('node:path');
const initSqlJs = require('sql.js');

async function main() {
  const prismaDir = path.resolve(__dirname, '../prisma');
  const databasePath = path.join(prismaDir, 'dev.db');
  const migrationPath = path.join(
    prismaDir,
    'migrations/20260930190000_init/migration.sql',
  );
  const SQL = await initSqlJs({
    locateFile: (file) => require.resolve(`sql.js/dist/${file}`),
  });

  const db = fs.existsSync(databasePath)
    ? new SQL.Database(fs.readFileSync(databasePath))
    : new SQL.Database();

  const existingTables = db.exec(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'User'",
  );
  if (!existingTables.length || !existingTables[0].values.length) {
    db.run(fs.readFileSync(migrationPath, 'utf8'));
  }

  fs.mkdirSync(prismaDir, { recursive: true });
  fs.writeFileSync(databasePath, Buffer.from(db.export()));
  db.close();
  console.log(`SQLite prêt : ${databasePath}`);
}

main().catch((error) => {
  console.error('Échec de l’initialisation SQLite :', error);
  process.exitCode = 1;
});
