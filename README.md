# BiSWish - Best in Slot Wishlist Addon

A World of Warcraft addon for managing and tracking Best in Slot (BiS) items for raid groups and guilds. Keep track of who wants what loot and automatically open your wishlist when guild raids kill bosses!

## 🎯 What Does It Do?

- **Track BiS Items**: Create wishlists for your raid group
- **Import from Spreadsheets**: Copy data from Google Sheets or Excel
- **Auto-Open on Boss Kills**: Automatically shows your wishlist during guild raids
- **Guild Integration**: Auto-detects and displays your guild name
- **Smart Guild Detection**: Automatically fills in your guild name when you open settings
- **Easy Management**: Add, edit, and remove items with a simple interface

## 🚀 Quick Start

1. **Install**: Download and place in your AddOns folder
2. **Enable**: Turn on in the WoW AddOns menu
3. **Configure**: Go to Interface → AddOns → BiSWish
4. **Set Guild Name**: Enter your guild/raid team name
5. **Import Data**: Use the Data Management panel to import your spreadsheet

## 📖 How to Use

### Commands
- `/bis` - Open your BiS wishlist
- `/bis help` - Show help
- `/bis data` - Open data management window
- `/bis options` - Open settings
- `/bis testdrop` - Test item drop popup
- `/bis debug` - Toggle debug mode
- `/bis debuglevel <1-5>` - Set debug level

### Settings
- **General**: Set your guild name and auto-open options
- **Data Management**: Import CSV data, view items, add items manually
- **Advanced**: Debug mode for troubleshooting
- **Auto-Fill Guild Name**: Click the "Auto-fill" button to automatically detect your guild name

### Importing Data
1. Format your spreadsheet as: `Player,Trinket 1,Trinket 2,Weapon 1,Weapon 2,Description`
2. Copy the data to your clipboard
3. Go to Settings → BiSWish → Data Management → Import CSV Data
4. Paste your data and click Import

## 🎨 Features

- **Smart Icons**: Automatically shows the right item icons
- **Search & Filter**: Find items and players quickly
- **Tooltips**: Hover over items to see details
- **Guild Integration**: Auto-opens during guild raids
- **Auto-Detect Guild**: Automatically detects and fills your guild name
- **Persistent Data**: All your data is saved between sessions
- **Debug System**: Built-in debug mode for troubleshooting

## 🐛 Troubleshooting

**Addon not working?**
- Make sure it's enabled in the AddOns menu
- Try typing `/reload` in-game
- Check that your guild name is set in settings

**Import not working?**
- Make sure your CSV format is correct
- Check that all columns are filled properly
- Try copying and pasting the data again

**Guild name not showing?**
- Go to Settings → BiSWish → General
- Click the "Auto-fill" button next to the guild name field
- Or manually enter your guild/raid team name
- The name will appear in your BiS list

**Need help debugging?**
- Type `/bis debug` to enable debug mode
- Use `/bis debuglevel <1-5>` to set debug verbosity
- Check the chat for debug messages

## 📝 Version History

### Version 1.1
- Added auto-detect guild name functionality
- Added "Auto-fill" button for guild name detection
- Enhanced debug system with configurable levels
- Improved settings integration
- Better error handling and user feedback

### Version 1.0
- Initial release
- BiS wishlist management
- CSV import from spreadsheets
- Guild raid auto-open
- Settings integration
- Smart icon matching

## 🎮 Requirements

- **WoW Version**: Dragonflight (10.2.7+)
- **Dependencies**: None
- **Languages**: English

---

**BiSWish** - Keep track of your raid loot wishes! 🗡️