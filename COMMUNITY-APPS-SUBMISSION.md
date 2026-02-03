# Stoat Chat - Community Apps Submission Guide

This guide explains how to submit Stoat Chat to the Unraid Community Applications repository.

## 📋 What We've Created

### 1. Configuration Options
We've created multiple template files for different use cases:

- **`stoat-chat-simple.xml`** - Recommended for Community Apps submission
- **`stoat-chat-enhanced.xml`** - Full configuration options (advanced users)
- **`config-generator.html`** - Web-based configuration generator

### 2. Web Configuration Generator
- Located at: `config-generator.html`
- Provides easy setup for both domain and Tailscale deployments
- Generates secure credentials automatically
- Creates step-by-step installation commands
- Should be hosted at: `https://YOUR_USERNAME.github.io/stoat-unraid/config-generator.html`

## 🚀 Submission Process

### Step 1: Prepare Your Repository

1. **Update Repository URLs**
   Replace `YOUR_USERNAME` with your actual GitHub username in:
   - `community-apps/stoat-chat-simple.xml`
   - `community-apps/stoat-chat-enhanced.xml`
   - `config-generator.html`

2. **Host Configuration Generator**
   - Enable GitHub Pages for your repository
   - The generator will be available at: `https://yourusername.github.io/stoat-unraid/config-generator.html`

3. **Test Your Setup**
   - Ensure the setup script works properly
   - Test both domain and Tailscale modes
   - Verify the configuration generator produces working configs

### Step 2: Submit to Community Apps

1. **Fork the Community Apps Repository**
   ```bash
   git clone https://github.com/Squidly271/Community-Applications-Moderators.git
   cd Community-Applications-Moderators
   ```

2. **Add Your Template**
   - Copy `community-apps/stoat-chat-simple.xml` to the appropriate directory in the Community Apps repo
   - Follow their directory structure (usually organized by category)

3. **Create Pull Request**
   - Submit a pull request with your template
   - Include clear description of what Stoat Chat provides
   - Mention the configuration generator for easy setup

### Step 3: Template Information

#### For Community Apps Moderators:

**Application Name:** Stoat Chat  
**Category:** Network:Chat  
**Description:** Self-hosted Discord alternative with Tailscale support  
**Key Features:**
- Real-time messaging platform
- Two deployment modes: Public domain or Tailscale VPN
- Web-based configuration generator for easy setup
- Multi-container Docker Compose application
- File sharing and multimedia support

**Special Notes:**
- Requires Docker Compose Manager plugin
- Includes configuration generator for user-friendly setup
- Supports both public and private (Tailscale) deployments
- Comprehensive documentation and setup scripts

## 📖 Documentation Structure

### Required Files for Submission:
- `stoat-chat-simple.xml` - Main Community Apps template
- `README.md` - Updated with Community Apps information
- `config-generator.html` - Web configuration tool
- `setup-unraid.sh` - Automated setup script
- `UNRAID-GUI-INSTALL.md` - Installation guide

### Optional Files (for advanced users):
- `stoat-chat-enhanced.xml` - Full configuration template
- `TAILSCALE-SETUP.md` - Detailed Tailscale guide
- `COMMUNITY-APPS-SUBMISSION.md` - This file

## 🔧 Configuration Features

### Basic Configuration:
- ✅ Domain/hostname setup
- ✅ Data storage paths
- ✅ Port configuration
- ✅ Deployment mode selection

### Advanced Configuration:
- ✅ Tailscale VPN integration
- ✅ Security settings (invite-only, credentials)
- ✅ Optional features (Tenor GIF search, push notifications)
- ✅ Reverse proxy support
- ✅ Custom paths and ports

### Auto-generated Security:
- ✅ Secure random passwords
- ✅ VAPID keys for push notifications
- ✅ File encryption keys
- ✅ Database credentials

## 🎯 User Experience

### Simple Installation Flow:
1. User installs template from Community Apps
2. User visits configuration generator web page
3. Generator creates all necessary configuration files
4. User runs generated setup commands
5. Stoat Chat is ready to use

### Advanced Installation Flow:
1. User downloads enhanced template
2. User configures all options manually
3. User runs setup script with custom parameters
4. Advanced features configured as needed

## 📋 Pre-submission Checklist

- [ ] All `YOUR_USERNAME` placeholders replaced with actual username
- [ ] GitHub Pages enabled and configuration generator accessible
- [ ] Setup script tested with both deployment modes
- [ ] All documentation updated and accurate
- [ ] Template XML validates properly
- [ ] Repository is public and accessible
- [ ] All required dependencies documented
- [ ] Support links point to correct repositories

## 🔗 Important Links

After submission, users will access:
- **Configuration Generator:** `https://yourusername.github.io/stoat-unraid/config-generator.html`
- **Main Repository:** `https://github.com/yourusername/stoat-unraid`
- **Documentation:** Repository README and guides
- **Support:** GitHub Issues in your repository

## 💡 Tips for Approval

1. **Clear Documentation:** Ensure all setup steps are clearly documented
2. **Working Examples:** Test the configuration generator thoroughly
3. **Security Focus:** Highlight the security benefits of Tailscale mode
4. **User-Friendly:** Emphasize the ease of setup with the web generator
5. **Complete Package:** Include all necessary files and dependencies
6. **Support Plan:** Be ready to provide support through GitHub Issues

## 🆘 Support & Maintenance

After Community Apps approval:
- Monitor GitHub Issues for user support requests
- Keep the template updated with new Stoat releases
- Update documentation as needed
- Maintain the configuration generator
- Respond to Community Apps moderator requests

---

**Note:** This is a comprehensive setup for a complex multi-container application. The combination of simple Community Apps integration with a powerful configuration generator provides both ease of use and advanced functionality for different user needs.
