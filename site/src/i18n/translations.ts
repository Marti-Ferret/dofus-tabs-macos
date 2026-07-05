export const languages = ["es", "en", "fr"] as const;
export type Lang = (typeof languages)[number];

export const defaultLang: Lang = "es";

export interface FeatureCopy {
	title: string;
	text: string;
	path: string;
}

export interface StepCopy {
	title: string;
	text: string;
}

export interface RequirementCopy {
	label: string;
	text: string;
}

export interface SiteCopy {
	meta: { title: string; description: string };
	nav: { features: string; requirements: string; github: string };
	hero: {
		eyebrow: string;
		titlePre: string;
		titleAccent: string;
		titlePost: string;
		ledePre: string;
		ledePost: string;
		ctaDownload: string;
		ctaCode: string;
		fineprint: string;
	};
	problema: {
		eyebrow: string;
		title: string;
		text: string;
		stat1Value: string;
		stat1Text: string;
		stat2Value: string;
		stat2Text: string;
		stat3Value: string;
		stat3Text: string;
	};
	features: { eyebrow: string; title: string; items: FeatureCopy[] };
	como: { eyebrow: string; title: string; steps: StepCopy[]; keyboardTitle: string; keyboardTextPre: string; keyboardTextMid: string; keyboardTextPost: string };
	requisitos: { eyebrow: string; title: string; items: RequirementCopy[] };
	footer: { disclaimer: string; github: string; license: string };
}

const featurePaths = [
	"M3 4h18v14H3zM3 9h18",
	"M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z",
	"M2 6h20v12H2zM6 10h.01M10 10h.01M14 10h.01M18 10h.01M6 14h12",
	"M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z",
	"M12 3a9 9 0 100 18 9 9 0 000-18zM9 9l6 6M15 9l-6 6",
	"M12 2v4M12 18v4M4.9 4.9l2.8 2.8M16.3 16.3l2.8 2.8M2 12h4M18 12h4M4.9 19.1l2.8-2.8M16.3 7.7l2.8-2.8",
];

export const translations: Record<Lang, SiteCopy> = {
	es: {
		meta: {
			title: "Dofus Tabs — organiza tus ventanas multicuenta en macOS",
			description: "Organizador de ventanas multicuenta para Dofus, nativo de macOS. Detección automática, atajos personalizables y tileado de ventanas.",
		},
		nav: { features: "Funciones", requirements: "Requisitos", github: "GitHub" },
		hero: {
			eyebrow: "macOS · gratis · código abierto",
			titlePre: "Deja de rebuscar entre ",
			titleAccent: "ventanas de Dofus",
			titlePost: " con Alt+Tab.",
			ledePre: "Un icono en la barra de menú que ve todas tus cuentas a la vez. Salta a cualquiera con",
			ledePost: ", tilea la pantalla entera de un tirón, y elige tú mismo qué tecla hace qué.",
			ctaDownload: "↓ Descargar última versión",
			ctaCode: "Ver el código",
			fineprint: "macOS 13 o superior · sin firma Developer ID: hay que confirmar la apertura una vez",
		},
		problema: {
			eyebrow: "Por qué existe esto",
			title: "En Windows hay media docena de estas herramientas. En Mac, ninguna que funcione bien.",
			text: "Investigamos el ecosistema entero antes de escribir una línea de código: siete proyectos activos, casi todos en C#/WinUI, ninguno para Mac salvo un intento de 2024 hecho con Electron y AppleScript, abandonado a los siete commits.",
			stat1Value: "7 / 7",
			stat1Text: "Herramientas serias del ecosistema Dofus son Windows-only.",
			stat2Value: "2024",
			stat2Text: "Última actividad del único intento nativo de macOS que existía.",
			stat3Value: "AXUIElement",
			stat3Text: "Nada de AppleScript: foco y tileado por Accessibility API, instantáneo.",
		},
		features: {
			eyebrow: "Funcionalidades",
			title: "Lo justo para llevar 4, 6 u 8 cuentas sin perder ni un segundo.",
			items: [
				{ title: "Detección automática", text: "Encuentra tus ventanas de Dofus solas, sin configurar nada — vía Accessibility API, no un script frágil de ps aux.", path: featurePaths[0] },
				{ title: "Miniaturas reales", text: "Un screenshot pequeño de cada ventana, no un icono genérico — sabes quién es quién de un vistazo.", path: featurePaths[1] },
				{ title: "Atajos a tu gusto", text: "Clica un atajo y pulsa la combinación que quieras. El ciclo, el tileado, y cada personaje son reasignables.", path: featurePaths[2] },
				{ title: "Organiza en cuadrícula", text: "Un atajo reparte todas las ventanas activas en pantalla, sin arrastrar nada a mano.", path: featurePaths[3] },
				{ title: "Excluye a los mules", text: "Saca una cuenta de la rotación de atajos sin cerrarla — sigue en el menú, solo que fuera del ciclo.", path: featurePaths[4] },
				{ title: "Arranca sola", text: "Actívala una vez y te espera en la barra de menú cada vez que enciendes el Mac.", path: featurePaths[5] },
			],
		},
		como: {
			eyebrow: "En la práctica",
			title: "De instalar a jugar, tres pasos.",
			steps: [
				{ title: "Ábrela una vez", text: "Concede permiso de Accesibilidad y de Grabación de pantalla — son los dos que necesita para ver y mover tus ventanas." },
				{ title: "Abre tus cuentas", text: "Cada personaje aparece solo en el menú, con su miniatura y su atajo asignado." },
			],
			keyboardTitle: "Juega con el teclado",
			keyboardTextPre: "",
			keyboardTextMid: " para saltar directo, ",
			keyboardTextPost: " para organizar todo en pantalla.",
		},
		requisitos: {
			eyebrow: "Antes de instalar",
			title: "Requisitos y permisos",
			items: [
				{ label: "Sistema", text: "macOS 13 (Ventura) o superior, chip Apple Silicon o Intel." },
				{ label: "Accesibilidad", text: "obligatorio — sin esto no puede detectar ni enfocar ventanas de Dofus." },
				{ label: "Grabación de pantalla", text: "opcional — sin esto funciona igual, pero sin miniaturas de personaje." },
				{ label: "Firma", text: "ad-hoc, no Developer ID — la primera apertura pide confirmar con clic derecho → Abrir." },
			],
		},
		footer: {
			disclaimer: "Dofus Tabs es un proyecto de fan, sin afiliación con Ankama. Dofus es marca registrada de Ankama. No incluye ni incluirá input broadcasting ni automatización de eventos del juego — solo gestión de ventanas.",
			github: "GitHub",
			license: "Licencia MIT",
		},
	},

	en: {
		meta: {
			title: "Dofus Tabs — organize your multi-account Dofus windows on macOS",
			description: "Multi-account window organizer for Dofus, native to macOS. Automatic detection, customizable shortcuts, and window tiling.",
		},
		nav: { features: "Features", requirements: "Requirements", github: "GitHub" },
		hero: {
			eyebrow: "macOS · free · open source",
			titlePre: "Stop digging through ",
			titleAccent: "Dofus windows",
			titlePost: " with Alt+Tab.",
			ledePre: "A menu bar icon that sees all your accounts at once. Jump to any of them with",
			ledePost: ", tile the whole screen in one go, and pick which key does what yourself.",
			ctaDownload: "↓ Download latest release",
			ctaCode: "View the code",
			fineprint: "macOS 13 or later · no Developer ID signature: you'll need to confirm opening it once",
		},
		problema: {
			eyebrow: "Why this exists",
			title: "Windows has half a dozen of these tools. Mac has none that work well.",
			text: "We researched the whole ecosystem before writing a line of code: seven active projects, almost all C#/WinUI, none for Mac except a 2024 attempt built with Electron and AppleScript, abandoned after seven commits.",
			stat1Value: "7 / 7",
			stat1Text: "Serious tools in the Dofus ecosystem are Windows-only.",
			stat2Value: "2024",
			stat2Text: "Last activity on the only native macOS attempt that existed.",
			stat3Value: "AXUIElement",
			stat3Text: "No AppleScript: focus and tiling through the Accessibility API, instant.",
		},
		features: {
			eyebrow: "Features",
			title: "Just enough to run 4, 6, or 8 accounts without losing a second.",
			items: [
				{ title: "Automatic detection", text: "Finds your Dofus windows on its own, no setup needed — via the Accessibility API, not a fragile ps aux script.", path: featurePaths[0] },
				{ title: "Real thumbnails", text: "A small screenshot of each window, not a generic icon — you know who's who at a glance.", path: featurePaths[1] },
				{ title: "Shortcuts your way", text: "Click a shortcut and press whatever combination you want. The cycle, the tiling, and every character are reassignable.", path: featurePaths[2] },
				{ title: "Arrange into a grid", text: "One shortcut spreads every active window across the screen — no dragging by hand.", path: featurePaths[3] },
				{ title: "Exclude your mules", text: "Take an account out of the shortcut rotation without closing it — it stays in the menu, just out of the cycle.", path: featurePaths[4] },
				{ title: "Starts on its own", text: "Turn it on once and it's waiting in the menu bar every time you start your Mac.", path: featurePaths[5] },
			],
		},
		como: {
			eyebrow: "In practice",
			title: "From install to playing, three steps.",
			steps: [
				{ title: "Open it once", text: "Grant Accessibility and Screen Recording permission — the two it needs to see and move your windows." },
				{ title: "Open your accounts", text: "Each character shows up on its own in the menu, with its thumbnail and assigned shortcut." },
			],
			keyboardTitle: "Play with the keyboard",
			keyboardTextPre: "",
			keyboardTextMid: " to jump straight there, ",
			keyboardTextPost: " to arrange everything on screen.",
		},
		requisitos: {
			eyebrow: "Before installing",
			title: "Requirements and permissions",
			items: [
				{ label: "System", text: "macOS 13 (Ventura) or later, Apple Silicon or Intel chip." },
				{ label: "Accessibility", text: "required — without it, it can't detect or focus Dofus windows." },
				{ label: "Screen Recording", text: "optional — it still works without it, just without character thumbnails." },
				{ label: "Signature", text: "ad-hoc, not Developer ID — the first launch needs confirming with right-click → Open." },
			],
		},
		footer: {
			disclaimer: "Dofus Tabs is a fan project, not affiliated with Ankama. Dofus is a registered trademark of Ankama. It doesn't include, and never will, input broadcasting or game-event automation — window management only.",
			github: "GitHub",
			license: "MIT License",
		},
	},

	fr: {
		meta: {
			title: "Dofus Tabs — organisez vos fenêtres multicomptes Dofus sur macOS",
			description: "Organisateur de fenêtres multicomptes pour Dofus, natif macOS. Détection automatique, raccourcis personnalisables et organisation des fenêtres en grille.",
		},
		nav: { features: "Fonctionnalités", requirements: "Prérequis", github: "GitHub" },
		hero: {
			eyebrow: "macOS · gratuit · open source",
			titlePre: "Arrêtez de fouiller entre les ",
			titleAccent: "fenêtres de Dofus",
			titlePost: " avec Alt+Tab.",
			ledePre: "Une icône dans la barre de menu qui voit tous vos comptes à la fois. Sautez vers n'importe lequel avec",
			ledePost: ", organisez tout l'écran en un clic, et choisissez vous-même quelle touche fait quoi.",
			ctaDownload: "↓ Télécharger la dernière version",
			ctaCode: "Voir le code",
			fineprint: "macOS 13 ou supérieur · pas de signature Developer ID : il faut confirmer l'ouverture une fois",
		},
		problema: {
			eyebrow: "Pourquoi ce projet existe",
			title: "Sous Windows, il existe une demi-douzaine de ces outils. Sur Mac, aucun qui fonctionne bien.",
			text: "Nous avons étudié tout l'écosystème avant d'écrire une seule ligne de code : sept projets actifs, presque tous en C#/WinUI, aucun pour Mac à part une tentative de 2024 faite avec Electron et AppleScript, abandonnée au bout de sept commits.",
			stat1Value: "7 / 7",
			stat1Text: "Des outils sérieux de l'écosystème Dofus sont réservés à Windows.",
			stat2Value: "2024",
			stat2Text: "Dernière activité de la seule tentative native macOS qui existait.",
			stat3Value: "AXUIElement",
			stat3Text: "Pas d'AppleScript : focus et organisation via l'Accessibility API, instantané.",
		},
		features: {
			eyebrow: "Fonctionnalités",
			title: "Juste ce qu'il faut pour gérer 4, 6 ou 8 comptes sans perdre une seconde.",
			items: [
				{ title: "Détection automatique", text: "Trouve vos fenêtres Dofus toute seule, sans rien configurer — via l'Accessibility API, pas un script fragile en ps aux.", path: featurePaths[0] },
				{ title: "Miniatures réelles", text: "Une petite capture d'écran de chaque fenêtre, pas une icône générique — vous savez qui est qui d'un coup d'œil.", path: featurePaths[1] },
				{ title: "Raccourcis à votre goût", text: "Cliquez sur un raccourci et appuyez sur la combinaison de votre choix. Le cycle, l'organisation en grille et chaque personnage sont réassignables.", path: featurePaths[2] },
				{ title: "Organise en grille", text: "Un raccourci répartit toutes les fenêtres actives à l'écran, sans rien glisser à la main.", path: featurePaths[3] },
				{ title: "Exclut vos mules", text: "Sortez un compte de la rotation des raccourcis sans le fermer — il reste dans le menu, juste hors du cycle.", path: featurePaths[4] },
				{ title: "Se lance toute seule", text: "Activez-la une fois et elle vous attend dans la barre de menu à chaque démarrage de votre Mac.", path: featurePaths[5] },
			],
		},
		como: {
			eyebrow: "En pratique",
			title: "De l'installation au jeu, trois étapes.",
			steps: [
				{ title: "Ouvrez-la une fois", text: "Accordez l'accès Accessibilité et Enregistrement de l'écran — les deux dont elle a besoin pour voir et déplacer vos fenêtres." },
				{ title: "Ouvrez vos comptes", text: "Chaque personnage apparaît tout seul dans le menu, avec sa miniature et son raccourci assigné." },
			],
			keyboardTitle: "Jouez au clavier",
			keyboardTextPre: "",
			keyboardTextMid: " pour sauter directement, ",
			keyboardTextPost: " pour tout organiser à l'écran.",
		},
		requisitos: {
			eyebrow: "Avant d'installer",
			title: "Prérequis et autorisations",
			items: [
				{ label: "Système", text: "macOS 13 (Ventura) ou supérieur, puce Apple Silicon ou Intel." },
				{ label: "Accessibilité", text: "obligatoire — sans cela, impossible de détecter ou de mettre le focus sur les fenêtres Dofus." },
				{ label: "Enregistrement de l'écran", text: "optionnel — fonctionne quand même sans, mais sans miniatures de personnage." },
				{ label: "Signature", text: "ad-hoc, pas de Developer ID — le premier lancement demande de confirmer avec clic droit → Ouvrir." },
			],
		},
		footer: {
			disclaimer: "Dofus Tabs est un projet de fan, sans affiliation avec Ankama. Dofus est une marque déposée d'Ankama. Il n'inclut et n'inclura jamais d'input broadcasting ni d'automatisation des événements du jeu — uniquement de la gestion de fenêtres.",
			github: "GitHub",
			license: "Licence MIT",
		},
	},
};

export function pathForLang(lang: Lang): string {
	return lang === defaultLang ? "/" : `/${lang}/`;
}
