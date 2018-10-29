Overview
========

Euphrates is a key logger for Windows.
It was tested on Windows 98 and Windows XP.
It's unlikely to work correctly on any modern Windows system.

Contents
========

The program consists of two files:

• EUPHRATES.EXE - the main executable
• HOOKER.DLL - an auxiliary library

Feel free to rename them as you see fit.

Command-line interface
======================

• Run the program without arguments to start key logging:

  EUPHRATES.EXE

• You can check if the key logger is running:

  EUPHRATES.EXE /running

  The program will beep if it's running.

• You can make the key logger start on every boot:

  EUPHRATES.EXE /install

• The default output file name is “C:\output.txt”.
  The default auxiliary library name is “HOOKER.DLL”.
  You can configure the program to use different names:

  EUPHRATES.EXE /config X:\path\to\key.log hooklibname.dll

• The program does nothing when it encounters unknown arguments.

Usage
=====

Euphrates logs all key presses, with some exceptions:

• Scroll-Lock pauses logging for 5 minutes

• Alt + Scroll-Lock disables logging

