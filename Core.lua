--[[
================================================================================
Core.lua - BiSWish Addon Core Module
================================================================================
This module contains the core functionality for the BiSWish addon including:
- Database structure and initialization
- Debug system with configurable levels
- Core utility functions
- Addon-wide constants and configuration

Author: BiSWish Development Team
Version: 1.0
================================================================================
--]]

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

-- Get addon namespace
local addonName, ns = ...

-- Create core namespace
ns.Core = ns.Core or {}

-- ============================================================================
-- CONSTANTS AND CONFIGURATION
-- ============================================================================

--[[
    Debug levels for the debug system
    Higher numbers include all lower levels
--]]
local DEBUG_LEVELS = {
    ERROR = 1,      -- Critical errors only
    WARNING = 2,    -- Warnings and errors
    INFO = 3,       -- General information (default)
    DEBUG = 4,      -- Debug information
    VERBOSE = 5     -- Verbose debugging
}

-- ============================================================================
-- DATABASE STRUCTURE
-- ============================================================================

--[[
    Main addon database structure
    This is the persistent storage for all addon data
--]]
BiSWishAddonDB = BiSWishAddonDB or {
    items = {},     -- itemID -> {name, players = {player1, player2, ...}}
    options = {},   -- Options will be initialized by Options module
    version = 1     -- Database version for migration purposes
}

-- ============================================================================
-- DEBUG SYSTEM
-- ============================================================================

--[[
    Main debug print function
    @param level (number) - Debug level (1-5)
    @param message (string) - Message to print
    @param ... (any) - Additional arguments for string formatting
--]]
function ns.Core.DebugPrint(level, message, ...)
    local debugMode = ns.Options and ns.Options.GetOption("debugMode") or BiSWishAddonDB.options.debugMode
    if not debugMode then return end
    
    local debugLevel = ns.Options and ns.Options.GetOption("debugLevel") or BiSWishAddonDB.options.debugLevel
    if not debugLevel then debugLevel = DEBUG_LEVELS.INFO end
    
    if level > debugLevel then return end
    
    local levelNames = {
        [DEBUG_LEVELS.ERROR] = "|cffFF0000[ERROR]|r",
        [DEBUG_LEVELS.WARNING] = "|cffFFA500[WARNING]|r", 
        [DEBUG_LEVELS.INFO] = "|cff39FF14[INFO]|r",
        [DEBUG_LEVELS.DEBUG] = "|cff00FFFF[DEBUG]|r",
        [DEBUG_LEVELS.VERBOSE] = "|cffFF69B4[VERBOSE]|r"
    }
    
    local formattedMessage = string.format(message, ...)
    print("|cff39FF14BiSWish|r " .. levelNames[level] .. " " .. formattedMessage)
end

--[[
    Convenience functions for different debug levels
    These functions provide easy access to specific debug levels
--]]

--[[
    Print error messages
    @param message (string) - Error message
    @param ... (any) - Additional arguments for string formatting
--]]
function ns.Core.DebugError(message, ...)
    ns.Core.DebugPrint(DEBUG_LEVELS.ERROR, message, ...)
end

--[[
    Print warning messages
    @param message (string) - Warning message
    @param ... (any) - Additional arguments for string formatting
--]]
function ns.Core.DebugWarning(message, ...)
    ns.Core.DebugPrint(DEBUG_LEVELS.WARNING, message, ...)
end

--[[
    Print info messages
    @param message (string) - Info message
    @param ... (any) - Additional arguments for string formatting
--]]
function ns.Core.DebugInfo(message, ...)
    ns.Core.DebugPrint(DEBUG_LEVELS.INFO, message, ...)
end

--[[
    Print debug messages
    @param message (string) - Debug message
    @param ... (any) - Additional arguments for string formatting
--]]
function ns.Core.DebugDebug(message, ...)
    ns.Core.DebugPrint(DEBUG_LEVELS.DEBUG, message, ...)
end

--[[
    Print verbose messages
    @param message (string) - Verbose message
    @param ... (any) - Additional arguments for string formatting
--]]
function ns.Core.DebugVerbose(message, ...)
    ns.Core.DebugPrint(DEBUG_LEVELS.VERBOSE, message, ...)
end

-- ============================================================================
-- DEBUG MANAGEMENT FUNCTIONS
-- ============================================================================

--[[
    Set debug level
    @param level (number) - Debug level (1-5)
--]]
function ns.Core.SetDebugLevel(level)
    if level >= DEBUG_LEVELS.ERROR and level <= DEBUG_LEVELS.VERBOSE then
        if ns.Options then
            ns.Options.SetOption("debugLevel", level)
        else
            BiSWishAddonDB.options.debugLevel = level
        end
        local levelNames = {"ERROR", "WARNING", "INFO", "DEBUG", "VERBOSE"}
        ns.Core.DebugInfo("Debug level set to: %s", levelNames[level])
    end
end

--[[
    Toggle debug mode on/off
--]]
function ns.Core.ToggleDebugMode()
    if ns.Options then
        local currentMode = ns.Options.GetOption("debugMode")
        ns.Options.SetOption("debugMode", not currentMode)
    else
        BiSWishAddonDB.options.debugMode = not BiSWishAddonDB.options.debugMode
    end
    local newMode = ns.Options and ns.Options.GetOption("debugMode") or BiSWishAddonDB.options.debugMode
    ns.Core.DebugInfo("Debug mode %s", newMode and "enabled" or "disabled")
end

-- Initialize core system
-- ============================================================================
-- CORE INITIALIZATION
-- ============================================================================

--[[
    Initialize core module
    Sets up the core functionality and database
--]]
function ns.Core.Initialize()
    ns.Core.DebugInfo("Core system initialized!")
end
