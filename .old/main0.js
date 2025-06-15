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

    // --- SVG Icons (Blue, styled by CSS 'color' property via fill="currentColor") ---
    const moonSvgIcon = `
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="theme-icon" aria-hidden="true" focusable="false">
            <path d="M12 2.04C6.48 2.04 2 6.52 2 12s4.48 9.96 10 9.96c.99 0 1.95-.14 2.86-.42.28-.1.55-.24.8-.41-.91-.92-1.44-2.18-1.44-3.53 0-2.76 2.24-5 5-5 .29 0 .58.02.86.07-.52-2.88-2.93-5.09-5.86-5.52A9.946 9.946 0 0012 2.04z"/>
        </svg>`;

    const sunSvgIcon = `
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="theme-icon" aria-hidden="true" focusable="false">
            <path d="M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zM12 15c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3zm0-10c-.55 0-1 .45-1 1v1c0 .55.45 1 1 1s1-.45 1-1V6c0-.55-.45-1-1-1zm0 14c-.55 0-1 .45-1 1v1c0 .55.45 1 1 1s1-.45 1-1v-1c0-.55-.45-1-1-1zm-8-6c-.55 0-1 .45-1 1s.45 1 1 1h1c.55 0 1-.45 1-1s-.45-1-1-1H4zm14 0c-.55 0-1 .45-1 1s.45 1 1 1h1c.55 0 1-.45 1-1s-.45-1-1-1h-1zM6.34 7.76c-.39-.39-1.02-.39-1.41 0s-.39 1.02 0 1.41l.71.71c.39.39 1.02.39 1.41 0 .39-.39.39-1.02 0-1.41l-.71-.71zm11.32 9.88c-.39-.39-1.02-.39-1.41 0s-.39 1.02 0 1.41l.71.71c.39.39 1.02.39 1.41 0s.39-1.02 0-1.41l-.71-.71zM6.34 16.24l-.71.71c-.39.39-.39 1.02 0 1.41s1.02.39 1.41 0l.71-.71c.39-.39.39-1.02 0-1.41s-1.02-.39-1.41 0zm11.32-9.88l-.71.71c-.39-.39-.39 1.02 0 1.41s1.02.39 1.41 0l.71-.71c.39-.39.39-1.02 0-1.41s-1.02-.39-1.41 0z"/>
        </svg>`;
    // --- End of SVG Icons ---

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
        // Logo update logic (if any) remains the same
    }

    function toggleTheme() {
        // Ensure currentTheme has a fallback if data-theme is not yet set
        const currentTheme = htmlElement.getAttribute('data-theme') || 
                             (localStorage.getItem('theme') || 'light'); // Default to light if nothing is set
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