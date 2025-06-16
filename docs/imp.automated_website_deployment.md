### **Implementation Plan: Activating Automated Website Deployment**

**Objective:** To configure the `c` monorepo to automatically build and deploy the contents of the `web/` directory to GitHub Pages, and then transition the live custom domain to this new system.

**Prerequisites:**
*   You are logged into your GitHub account.
*   Your old `tea` repository is still serving your live website (this is our safety net).
*   You have a terminal open in the root directory of your local `c` repository (`/home/u/c`).

---

### **Phase 1: Create the Automation Workflow (Local Machine)**

In this phase, we will add the necessary files to tell GitHub *how* to deploy your site.

**Step 1.1: Create the Directory Structure**
Git doesn't track empty directories, so we need to create the folders and the workflow file in one go.

```bash
mkdir -p .github/workflows
```

**Step 1.2: Create the Workflow File**
Create the YAML file that will define the deployment job.

```bash
nano .github/workflows/deploy-pages.yml
```

**Step 1.3: Add the Workflow Code**
Paste the following code exactly as written into the `deploy-pages.yml` file. This is the "brain" of your deployment automation.

```yaml
# .github/workflows/deploy-pages.yml

name: Deploy Website to GitHub Pages

on:
  push:
    branches:
      - main
    paths:
      - 'web/**'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      - name: Setup Pages
        uses: actions/configure-pages@v4
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: './web'
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```
Save and close the file.

**Step 1.4: Commit and Push the Workflow**
Commit this new file to your repository. This action *enables* the automation on GitHub.

```bash
git add .github/workflows/deploy-pages.yml
git commit -m "feat: add GitHub Pages deployment workflow"
git push
```

---

### **Phase 2: Configure GitHub Pages (GitHub Website)**

Now, we will tell GitHub to use the new automation workflow we just added.

**Step 2.1: Navigate to Repository Settings**
Go to your `c` repository on GitHub. Click on **Settings**, then navigate to the **Pages** section in the left sidebar.

**Step 2.2: Set the Deployment Source**
Under the "Build and deployment" section, change the **Source** dropdown to **"GitHub Actions"**. This is the modern, recommended approach that uses your new workflow file.

---

### **Phase 3: Trigger and Verify the First Deployment**

The workflow is configured to only run when files in `web/` are changed. Let's trigger it with a test change.

**Step 3.1: Make a Test Change**
Make a small, harmless change to a file inside your `web/` directory. Adding a comment is a perfect, non-disruptive way to do this. For example, edit `web/index.html`.

**Step 3.2: Commit and Push the Test Change**
Use your script or commit manually. This push will trigger the workflow for the first time.

```bash
# Example using a manual commit
git commit -am "test: trigger initial pages deployment"
git push
```

**Step 3.3: Monitor the Workflow**
Go to the **"Actions"** tab of your `c` repository on GitHub. You will see the "Deploy Website to GitHub Pages" workflow running. Wait for it to complete successfully (it should get a green checkmark).

**Step 3.4: Verify the New Site URL**
Once the workflow is complete, your site will be deployed to a temporary URL. Verify that it looks correct by visiting:
`https://TechEliteAutomation.github.io/c/`

---

### **Phase 4: Go Live with Your Custom Domain**

Once you have verified the site at the temporary URL, you can perform the final cutover.

**Step 4.1: Deactivate the Old Site**
1.  Go to your **old `tea` repository** settings.
2.  Navigate to the **Pages** section.
3.  In the "Custom domain" section, **remove** your custom domain and save. This frees it up for use.

**Step 4.2: Activate the New Site**
1.  Go back to your **new `c` repository** settings.
2.  Navigate to the **Pages** section.
3.  In the "Custom domain" section, **enter your custom domain** (e.g., `yourdomain.com`) and click **Save**. This will trigger another deployment run to add the `CNAME` file.

**Step 4.3: Final Verification**
Wait a few minutes for DNS to update, then visit your custom domain. It should now be serving the website from your new `c` repository.

**Step 4.4: Archive the Old Repository**
Once you have confirmed the custom domain is working correctly, you can safely **Archive** your old `tea` repository.

You have now successfully completed the migration.
