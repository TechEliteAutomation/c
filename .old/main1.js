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

    // --- Refined SVG Icons (Styled by CSS 'color' property via fill="currentColor") ---
    const moonSvgIcon = `
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="theme-icon" aria-hidden="true" focusable="false">
          <path d="M12 3.00002C11.3854 3.00002 10.8187 3.40239 10.6521 4.00931C9.56202 7.52863 10.2471 11.4573 12.9075 14.1177C15.5679 16.7781 19.4966 17.4632 23.0159 16.3731C23.6228 16.2065 24.0252 15.6398 24.0252 15C24.0252 10.8511 21.1741 7.00002 17.0252 7.00002C15.8471 7.00002 14.7353 7.24447 13.7496 7.68282C10.0543 9.06148 7.02516 12.8543 7.02516 17.25C7.02516 17.8893 7.42753 18.456 8.03445 18.6226C11.5538 19.7127 15.4825 19.0276 18.1429 16.3672C16.4025 12.0122 12.8187 9.70408 8.90016 10.0543C5.20339 10.5564 3.02516 13.7041 3.02516 17.25C3.02516 19.5286 4.30802 21.5564 6.15016 22.65C6.31871 22.7556 6.51462 22.8093 6.71447 22.8093C6.89134 22.8093 7.06708 22.762 7.22474 22.6677C7.49661 22.5086 7.62516 22.1907 7.52863 21.9075C6.55633 19.0122 7.20339 15.8511 9.50016 13.5543C11.797 11.2575 14.958 10.6104 17.8533 11.5827C20.7864 12.9075 22.0252 15.0726 22.0252 17.475C22.0252 17.8893 21.6228 18.456 21.0159 18.6226C19.0122 19.2445 16.8002 19.3672 14.7496 18.9371C11.0543 17.578 8.02516 13.7851 8.02516 9.375C8.02516 8.73574 7.62279 8.16907 7.01587 8.0024C4.00002 7.02502 3.00002 4.15002 3.00002 4.00002C3.00002 3.44774 3.44774 3.00002 4.00002 3.00002H12.0247Z"/>
        </svg>`;

    const sunSvgIcon = `
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="theme-icon" aria-hidden="true" focusable="false">
          <path d="M12 16C14.2091 16 16 14.2091 16 12C16 9.79086 14.2091 8 12 8C9.79086 8 8 9.79086 8 12C8 14.2091 9.79086 16 12 16Z"/>
          <path d="M12 5C11.4477 5 11 5.44772 11 6V7C11 7.55228 11.4477 8 12 8C12.5523 8 13 7.55228 13 7V6C13 5.44772 12.5523 5 12 5Z"/>
          <path d="M12 17C11.4477 17 11 17.4477 11 18V19C11 19.5523 11.4477 20 12 20C12.5523 20 13 19.5523 13 19V18C13 17.4477 12.5523 17 12 17Z"/>
          <path d="M18.364 5.63604C17.9735 5.24551 17.3404 5.24551 16.9498 5.63604L16.2427 6.34315C15.8522 6.73367 15.8522 7.36684 16.2427 7.75736C16.6332 8.14788 17.2664 8.14788 17.6569 7.75736L18.364 7.05025C18.7545 6.65973 18.7545 6.02656 18.364 5.63604Z"/>
          <path d="M7.05025 5.63604C6.65973 5.24551 6.02656 5.24551 5.63604 5.63604C5.24551 6.02656 5.24551 6.65973 5.63604 7.05025L6.34315 7.75736C6.73367 8.14788 7.36684 8.14788 7.75736 7.75736C8.14788 7.36684 8.14788 6.73367 7.75736 6.34315L7.05025 5.63604Z"/>
          <path d="M18.364 18.364C18.7545 17.9735 18.7545 17.3404 18.364 16.9498L17.6569 16.2427C17.2664 15.8522 16.6332 15.8522 16.2427 16.2427C15.8522 16.6332 15.8522 17.2664 16.2427 17.6569L16.9498 18.364C17.3404 18.7545 17.9735 18.7545 18.364 18.364Z"/>
          <path d="M7.05025 18.364C7.44077 18.7545 8.07394 18.7545 8.46447 18.364L9.17157 17.6569C9.5621 17.2664 9.5621 16.6332 9.17157 16.2427C8.78105 15.8522 8.14788 15.8522 7.75736 16.2427L7.05025 16.9498C6.65973 17.3404 6.65973 17.9735 7.05025 18.364Z"/>
          <path d="M5 12C5 11.4477 5.44772 11 6 11H7C7.55228 11 8 11.4477 8 12C8 12.5523 7.55228 13 7 13H6C5.44772 13 5 12.5523 5 12Z"/>
          <path d="M17 12C17 11.4477 17.4477 11 18 11H19C19.5523 11 20 11.4477 20 12C20 12.5523 19.5523 13 19 13H18C17.4477 13 17 12.5523 17 12Z"/>
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