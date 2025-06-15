// START OF FILE: js/main.js
document.addEventListener('DOMContentLoaded', () => {
    // --- Mobile Menu Toggle ---
    const menuToggle = document.querySelector('.menu-toggle');
    const navMenuContainer = document.querySelector('.nav-menu-container');
    const navLinks = document.querySelectorAll('.nav-link');

    if (menuToggle && navMenuContainer) {
        const mobileNavContainer = document.getElementById('nav-menu');

        menuToggle.addEventListener('click', () => {
            const isExpanded = menuToggle.getAttribute('aria-expanded') === 'true';
            menuToggle.setAttribute('aria-expanded', !isExpanded);
            mobileNavContainer.classList.toggle('nav-menu-opened');
        });

        navLinks.forEach(link => {
            link.addEventListener('click', () => {
                if (getComputedStyle(menuToggle).display !== 'none' && mobileNavContainer.classList.contains('nav-menu-opened')) {
                    menuToggle.setAttribute('aria-expanded', 'false');
                    mobileNavContainer.classList.remove('nav-menu-opened');
                }
            });
        });
    }

    // --- Current Year in Footer ---
    const currentYearSpan = document.getElementById('current-year');
    if (currentYearSpan) {
        currentYearSpan.textContent = new Date().getFullYear();
    }

    // --- Theme Switcher Logic ---
    const themeSwitcher = document.getElementById('theme-switcher');
    const htmlElement = document.documentElement;

    // --- REFINED SVG Icons (Styled by CSS 'color' property via fill="currentColor") ---
	const moonSvgIcon = `
		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="theme-icon" aria-hidden="true" focusable="false">
			<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
		</svg>`;
    
	const sunSvgIcon = `
		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" class="theme-icon" aria-hidden="true" focusable="false">
			<circle cx="12" cy="12" r="4" fill="currentColor"/>
			<line x1="12" y1="2" x2="12" y2="6"/>
			<line x1="12" y1="18" x2="12" y2="22"/>
			<line x1="4.93" y1="4.93" x2="7.76" y2="7.76"/>
			<line x1="16.24" y1="16.24" x2="19.07" y2="19.07"/>
			<line x1="2" y1="12" x2="6" y2="12"/>
			<line x1="18" y1="12" x2="22" y2="12"/>
			<line x1="4.93" y1="19.07" x2="7.76" y2="16.24"/>
			<line x1="16.24" y1="7.76" x2="19.07" y2="4.93"/>
		</svg>`;

    function applyTheme(theme) {
        htmlElement.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);
        if (themeSwitcher) {
            if (theme === 'light') {
                themeSwitcher.innerHTML = moonSvgIcon; // Use SVG for moon
                themeSwitcher.setAttribute('aria-label', 'Switch to dark mode');
            } else {
                themeSwitcher.innerHTML = sunSvgIcon; // Use SVG for sun
                themeSwitcher.setAttribute('aria-label', 'Switch to light mode');
            }
        }
    }

    function toggleTheme() {
        const currentTheme = htmlElement.getAttribute('data-theme') || (localStorage.getItem('theme') || 'light');
        const newTheme = currentTheme === 'light' ? 'dark' : 'light';
        applyTheme(newTheme);
    }

    function initializeTheme() {
        const savedTheme = localStorage.getItem('theme');
        let currentTheme;

        if (savedTheme) {
            currentTheme = savedTheme;
        } else {
            currentTheme = 'light'; // Default to light theme
        }
        applyTheme(currentTheme);
    }

    if (themeSwitcher) {
        themeSwitcher.addEventListener('click', toggleTheme);
    }

    initializeTheme();
});
// END OF FILE: js/main.js
