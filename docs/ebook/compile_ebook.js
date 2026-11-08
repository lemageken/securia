const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const ebookDir = __dirname;
const rootDir = path.join(ebookDir, '..', '..');

// Étape 1 : Installer localement la dépendance légère 'marked' pour parser le Markdown
console.log("Installation du parseur Markdown (marked) en cours...");
try {
  execSync('npm install marked --no-save', { cwd: rootDir, stdio: 'inherit' });
} catch (e) {
  console.error("Échec de l'installation de 'marked'. Utilisation d'un parseur alternatif.");
}

const { marked } = require(path.join(rootDir, 'node_modules', 'marked'));

// Liste des chapitres dans l'ordre d'assemblage
const chapters = [
  '00_couverture_preface.md',
  '01_strategie_vision.md',
  '02_architecture_choix_tech.md',
  '03_guide_developpement.md',
  '04_infrastructure_deploiement.md',
  '05_business_model_evolution.md'
];

let fullMarkdown = '';

// Lire et concaténer les chapitres en ajoutant des sauts de page pour l'impression
chapters.forEach((file, index) => {
  const filePath = path.join(ebookDir, file);
  if (fs.existsSync(filePath)) {
    const content = fs.readFileSync(filePath, 'utf-8');
    fullMarkdown += content;
    if (index < chapters.length - 1) {
      fullMarkdown += '\n\n<div class="page-break"></div>\n\n';
    }
  } else {
    console.warn(`Fichier manquant : ${file}`);
  }
});

// Convertir le Markdown en HTML
const bodyContent = marked.parse(fullMarkdown);

// Template HTML complet avec style CSS d'édition premium et support d'impression PDF
const htmlTemplate = `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SECUR.IA - Livre Blanc Professionnel</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;600;700;800&display=swap');

    /* Variables de Charte Graphique SECUR.IA */
    :root {
      --primary-dark: #152A56;
      --accent-gold: #D97706;
      --electric-blue: #1E3A8A;
      --light-grey: #F8FAFC;
      --text-dark: #1E293B;
      --text-muted: #64748B;
    }

    body {
      font-family: 'Inter', sans-serif;
      color: var(--text-dark);
      line-height: 1.65;
      margin: 0;
      padding: 0;
      background-color: #FFFFFF;
    }

    .container {
      max-width: 850px;
      margin: 0 auto;
      padding: 60px 40px;
    }

    /* Titres & Typographie Premium */
    h1, h2, h3, h4 {
      font-family: 'Outfit', sans-serif;
      color: var(--primary-dark);
      font-weight: 700;
    }

    h1 {
      font-size: 2.4rem;
      margin-top: 50px;
      margin-bottom: 20px;
      border-bottom: 3px solid var(--accent-gold);
      padding-bottom: 10px;
      page-break-after: avoid;
    }

    h2 {
      font-size: 1.75rem;
      color: var(--electric-blue);
      margin-top: 35px;
      margin-bottom: 15px;
      page-break-after: avoid;
    }

    h3 {
      font-size: 1.35rem;
      margin-top: 25px;
      margin-bottom: 10px;
    }

    p {
      margin-bottom: 20px;
      text-align: justify;
      font-size: 1.05rem;
    }

    /* Mises en page spéciales (Citations & Encadrés) */
    blockquote {
      border-left: 5px solid var(--accent-gold);
      background-color: #FEF3C7; /* Fond ambré très doux */
      padding: 20px;
      margin: 30px 0;
      font-style: italic;
      font-size: 1.1rem;
      border-radius: 4px;
      color: #78350F;
    }

    /* Blocs de Code Source Dart / YAML stylisés */
    pre {
      background-color: #0F172A;
      color: #E2E8F0;
      padding: 24px;
      border-radius: 12px;
      font-size: 0.9rem;
      overflow-x: auto;
      margin: 25px 0;
      border: 1px solid #334155;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    }

    code {
      font-family: 'Fira Code', 'Courier New', Courier, monospace;
      background-color: #F1F5F9;
      color: #0F172A;
      padding: 3px 6px;
      border-radius: 4px;
      font-size: 0.9em;
    }

    pre code {
      background-color: transparent;
      color: inherit;
      padding: 0;
      font-size: inherit;
    }

    /* Tableaux de Synthèse */
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 30px 0;
      font-size: 0.95rem;
    }

    th, td {
      border: 1px solid #E2E8F0;
      padding: 14px 16px;
      text-align: left;
    }

    th {
      background-color: var(--primary-dark);
      color: #FFFFFF;
      font-weight: 600;
    }

    tr:nth-child(even) {
      background-color: var(--light-grey);
    }

    /* Page de Couverture Stylisée */
    .cover {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      min-height: 90vh;
      text-align: center;
      padding: 40px;
      box-sizing: border-box;
    }

    .cover h1 {
      font-size: 3.5rem;
      color: var(--primary-dark);
      border-bottom: none;
      margin-bottom: 10px;
      font-weight: 800;
    }

    .cover h2 {
      font-size: 1.8rem;
      color: var(--accent-gold);
      margin-top: 0;
      margin-bottom: 50px;
      font-weight: 400;
    }

    .divider {
      width: 150px;
      height: 4px;
      background-color: var(--electric-blue);
      margin: 30px 0;
    }

    .cover-meta {
      font-size: 1.1rem;
      color: var(--text-muted);
      margin-top: 50px;
    }

    /* Styles spécifiques pour l'impression / PDF */
    @media print {
      body {
        background-color: transparent;
        color: #000000;
      }
      .container {
        max-width: 100%;
        padding: 0;
      }
      .page-break {
        page-break-before: always;
        height: 0;
        margin: 0;
        border: none;
      }
      pre, blockquote, table {
        page-break-inside: avoid;
      }
      h1, h2, h3 {
        page-break-after: avoid;
      }
      a {
        text-decoration: none;
        color: #000000;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    ${bodyContent}
  </div>
</body>
</html>`;

// Écrire le fichier final SecurIA_Ebook.html
const outputHtmlPath = path.join(ebookDir, 'SecurIA_Ebook.html');
fs.writeFileSync(outputHtmlPath, htmlTemplate, 'utf-8');

console.log("\n==================================================");
console.log("🎉 SUCCÈS : L'eBook a été généré avec style !");
console.log(`Fichier HTML généré : ${outputHtmlPath}`);
console.log("==================================================\n");
