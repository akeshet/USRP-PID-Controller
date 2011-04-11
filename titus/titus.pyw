#!/usr/bin/env python
""" Copyright 2009 Ralf Gommers. All rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""


import sys
import os
import platform
import time
import webbrowser

from PyQt4.QtCore import *
from PyQt4.QtGui import *

import fpga_register_model as registers
import qrcresources


__version__ = "0.1.0"
MAC = "qt_mac_set_native_menubar" in dir()


class CentralWidget(QWidget):

    def __init__(self, parent=None):
        super(CentralWidget, self).__init__(parent)

        self.path = sys.path[0]
        self.firmwarefile = QString()
        self.bitfile = QString()
        self.postload_script = QString()

        self.model = registers.RegisterTableModel()
        tableLabel = QLabel("FPGA registers")
        self.tableView = QTableView()
        tableLabel.setBuddy(self.tableView)
        self.tableView.setModel(self.model)
        self.tableView.setItemDelegate(registers.RegisterDelegate(self))
        self.tableView.setAlternatingRowColors(True)

        saveConfigButton = QPushButton("&Save Config File")
        loadConfigButton = QPushButton("&Load Config File")
        autoLockButton = QPushButton("&Auto Lock")
        loadFirmwareButton = QPushButton("Load &Firmware")

        gridLayout = QGridLayout()
        filelabel1 = QLabel("Firmware file: ")
        gridLayout.addWidget(filelabel1, 0, 0, 1, 1)
        self.firmLineEdit = QLineEdit()
        gridLayout.addWidget(self.firmLineEdit, 0, 1, 1, 1)
        loadFirmFileButton = QPushButton("Browse")
        gridLayout.addWidget(loadFirmFileButton, 0, 2, 1, 1)
        filelabel2 = QLabel("FPGA bit file: ")
        gridLayout.addWidget(filelabel2, 1, 0, 1, 1)
        self.bitLineEdit = QLineEdit()
        gridLayout.addWidget(self.bitLineEdit, 1, 1, 1, 1)
        loadBitFileButton = QPushButton("Browse")
        gridLayout.addWidget(loadBitFileButton, 1, 2, 1, 1)
        filelabel3 = QLabel("Post-load script: ")
        gridLayout.addWidget(filelabel3, 2, 0, 1, 1)
        self.postLoadEdit = QLineEdit()
        gridLayout.addWidget(self.postLoadEdit, 2, 1, 1, 1)
        postLoadFileButton = QPushButton("Browse")
        gridLayout.addWidget(postLoadFileButton, 2, 2, 1, 1)


        if not MAC:
            saveConfigButton.setFocusPolicy(Qt.NoFocus)
            loadConfigButton.setFocusPolicy(Qt.NoFocus)
            autoLockButton.setFocusPolicy(Qt.NoFocus)
            loadFirmwareButton.setFocusPolicy(Qt.NoFocus)

        buttonLayout = QHBoxLayout()
        buttonLayout.addWidget(saveConfigButton)
        buttonLayout.addWidget(loadConfigButton)
        buttonLayout.addStretch()
        buttonLayout.addWidget(autoLockButton)
        buttonLayout.addStretch()
        buttonLayout.addWidget(loadFirmwareButton)
        splitter = QSplitter(Qt.Horizontal)
        vbox = QVBoxLayout()
        vbox.addWidget(tableLabel)
        vbox.addWidget(self.tableView)
        widget = QWidget()
        widget.setLayout(vbox)
        splitter.addWidget(widget)
        layout = QVBoxLayout()
        layout.addWidget(splitter)
        layout.addLayout(buttonLayout)
        layout.addLayout(gridLayout)
        self.setLayout(layout)

        header = self.tableView.horizontalHeader()

        self.connect(saveConfigButton, SIGNAL("clicked()"), self.saveConfigFile)
        self.connect(loadConfigButton, SIGNAL("clicked()"), self.loadConfigFile)
        self.connect(autoLockButton, SIGNAL("clicked()"), self.autoLock)
        self.connect(loadFirmwareButton, SIGNAL("clicked()"), self.loadFirmware)
        self.connect(loadFirmFileButton, SIGNAL("clicked()"), self.loadFirmFile)
        self.connect(loadBitFileButton, SIGNAL("clicked()"), self.loadBitFile)
        self.connect(postLoadFileButton, SIGNAL("clicked()"),
                     self.loadPostScriptFile)
        self.connect(self.firmLineEdit, SIGNAL("editingFinished()"),
                     self.fileNameEdited)
        self.connect(self.bitLineEdit, SIGNAL("editingFinished()"),
                     self.fileNameEdited)
        self.connect(self.postLoadEdit, SIGNAL("editingFinished()"),
                     self.fileNameEdited)


        self.connect(self.model, SIGNAL("registerSet"), self.updateProgressBar)


    def initialLoad(self):
        for register in registers.generate_registers():
            self.model.registers.append(register)
        self.model.reset()
        self.model.dirty = False


    def sizeHint(self):
        return QSize(800, 800)


    def getColumnWidths(self):
        colwidths = []
        for column in range(self.model.columnCount()):
            colwidths.append(self.tableView.columnWidth(column))
        return colwidths


    def setColumnWidths(self, colwidths):
        for column in range(self.model.columnCount()):
            self.tableView.setColumnWidth(column, colwidths[column])


    def saveConfigFile(self):
        fname = QFileDialog.getSaveFileName(self, "Save config file", self.path,
                                "Titus files (*.ttu);; All files (*.*)")
        if fname:
            name, ext = os.path.splitext(str(fname))
            # add extension if not supplied by the user
            if not ext:
                ext = '.ttu'
            fname = ''.join([name, ext])
            savedir, savefile = os.path.split(name)
            self.path = savedir

            self.model.save(fname)
        else:
            pass


    def loadConfigFile(self):
        fname = QFileDialog.getOpenFileName(self, "Load config file", self.path,
                                "Titus files (*.ttu);; All files (*.*)")
        if fname:
            loaddir, loadfile = os.path.split(str(fname))
            self.path = loaddir
            self.createProgressBar()
            self.model.load(fname)
            self.model.reset()
        else:
            pass


    def createProgressBar(self):
            self.progress = QProgressDialog()
            self.progress.setWindowModality(Qt.WindowModal)
            self.progress.setMinimumWidth(500)
            self.progress.setWindowTitle("Progress of loading settings")
            self.progress.setLabelText("Writing to registers...")
            self.progress.setCancelButton(None)
            self.progress.setMinimumDuration(1250)
            self.progress.setMaximum(len(self.model.registers)-1)
            self.progress.setValue(0)


    def updateProgressBar(self, num):
        """Update the value in the progress bar (created in loadConfigFile)."""
        try:
            self.progress.setValue(num)
            QApplication.processEvents()
        except AttributeError:
            # No progress dialog is displayed
            pass


    def loadFirmFile(self):
        fname = QFileDialog.getOpenFileName(self, "Load Firmware file",
                                            self.path,
                                "Firmware files (*.ihx);; All files (*.*)")
        if fname:
            loaddir, loadfile = os.path.split(str(fname))
            self.path = loaddir
            self.firmwarefile = fname
            self.firmLineEdit.setText(fname)


    def loadBitFile(self):
        fname = QFileDialog.getOpenFileName(self, "Load FPGA bit file",
                                            self.path,
                                "FPGA Bit files (*.rbf);; All files (*.*)")
        if fname:
            loaddir, loadfile = os.path.split(str(fname))
            self.path = loaddir
            self.bitfile = fname
            self.bitLineEdit.setText(fname)


    def loadPostScriptFile(self):
        fname = QFileDialog.getOpenFileName(self, "Load post-load script file",
                                            self.path,
                            "Post-load scriptfiles (*.sh);; All files (*.*)")
        if fname:
            loaddir, loadfile = os.path.split(str(fname))
            self.path = loaddir
            self.postload_script = fname
            self.postLoadEdit.setText(fname)


    def fileNameEdited(self):
        """Called if any of the line edits are edited."""

        text = self.sender().text()
        if self.sender()==self.firmLineEdit:
            self.firmwarefile = text
        elif self.sender()==self.bitLineEdit:
            self.bitfile = text
        elif self.sender()==self.loadPostScriptFile:
            self.postload_script = text


    def autoLock(self):
        pass


    def loadFirmware(self):
        """Loads the firmware files onto the board"""
        os.system('usrper load_firmware %s'%(str(self.firmwarefile)))
        time.sleep(1)
        os.system('usrper load_fpga %s'%(str(self.bitfile)))
        time.sleep(1)
        os.system('%s'%(str(self.postload_script)))
        self.askIfReWritingSettings()


    def askIfReWritingSettings(self):
        """After loading the firmware, does the user want to rewrite registers.

        All registers are initialized to zero when the firmware is updated.
        This function asks the user with a dialog if he/she wants to set the
        registers again to the values in the table. If not, does he/she want
        to save the values to a config file.
        """
        msgBox = QMessageBox()
        msgBox.setText("Re-output all register values?")
        msgBox.setInformativeText('Loading the firmware resets all registers to zero. Choose "Yes" to re-output the values currently in the register table.')
        msgBox.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
        msgBox.setDefaultButton(QMessageBox.Yes)
        msgBox.setMinimumWidth(500)

        answer = msgBox.exec_()
        if answer==msgBox.Yes:
            self.createProgressBar()
            self.model.set_registers()
        elif answer==msgBox.No:
            msgBox2 = QMessageBox()
            msgBox2.setText("Save config file?")
            msgBox2.setInformativeText('All values in table will be set to zero. Click "Yes" to save current values in a configuration file.')
            msgBox2.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
            #msgBox2.setDetailedText('...')
            msgBox2.setDefaultButton(QMessageBox.No)

            answer = msgBox2.exec_()
            if answer==msgBox2.Yes:
                self.saveConfigFile()
                self.model.allzero()
                self.model.reset()
            elif answer==msgBox2.No:
                self.model.allzero()
                self.model.reset()


class MainWindow(QMainWindow):

    def __init__(self, parent=None):
        super(MainWindow, self).__init__(parent)

        self.cwidget = CentralWidget()
        self.setCentralWidget(self.cwidget)

        self._restore_state()
        self.setWindowTitle("Titus the Usurper")
        self._populate_dropdown_menus()

        QTimer.singleShot(0, self.cwidget.initialLoad)


    def _save_state(self):
        """Save the state of the GUI."""
        settings = QSettings("Titus")
        settings.setValue("Geometry", QVariant(self.saveGeometry()))
        settings.setValue("MainWindow/State", QVariant(self.saveState()))
        settings.setValue("Path", QVariant(self.cwidget.path))
        settings.setValue("FirmwareFile", QVariant(self.cwidget.firmwarefile))
        settings.setValue("BitFile", QVariant(self.cwidget.bitfile))
        settings.setValue("PostLoadFile",
                          QVariant(self.cwidget.postload_script))

        # save column widths
        for num, width in enumerate(self.cwidget.getColumnWidths()):
            settings.setValue(''.join(["ColWidths/", str(num)]),
                              QVariant(width))


    def _restore_state(self):
        """Restore the state of the GUI from a previous session."""
        settings = QSettings("Titus")
        self.restoreGeometry(settings.value("Geometry").toByteArray())
        self.restoreState(settings.value("MainWindow/State").toByteArray())
        self.cwidget.path = QDir.toNativeSeparators(\
            settings.value("Path", QVariant(QDir.homePath())).toString())
        self.cwidget.firmwarefile = settings.value("FirmwareFile").toString()
        self.cwidget.bitfile = settings.value("BitFile").toString()
        self.cwidget.postload_script = settings.value("PostLoadFile").toString()
        self.cwidget.firmLineEdit.setText(self.cwidget.firmwarefile)
        self.cwidget.bitLineEdit.setText(self.cwidget.bitfile)
        self.cwidget.postLoadEdit.setText(self.cwidget.postload_script)

        # restore column widths (default is 100 for first time)
        colwidths = []
        for num in range(len(self.cwidget.getColumnWidths())):
            colwidths.append(settings.value(''.join(["ColWidths/", str(num)]),
                                            QVariant(100)).toInt()[0])
        self.cwidget.setColumnWidths(colwidths)


    def closeEvent(self, event=None):
        if self.cwidget.model.dirty and \
           QMessageBox.question(self, "Registers - Save?",
                    "Save unsaved changes?",
                    QMessageBox.Yes|QMessageBox.No) == QMessageBox.Yes:
            self.model.saveConfigFile()

        self._save_state()


    def createAction(self, text, slot=None, shortcut=None, icon=None,
                     tip=None, checkable=False, signal="triggered()"):
        action = QAction(text, self)
        if icon is not None:
            action.setIcon(QIcon(":/%s.png" % icon))
        if shortcut is not None:
            action.setShortcut(shortcut)
        if tip is not None:
            action.setToolTip(tip)
            action.setStatusTip(tip)
        if slot is not None:
            self.connect(action, SIGNAL(signal), slot)
        if checkable:
            action.setCheckable(True)
        return action


    def addActions(self, target, actions):
        for action in actions:
            if action is None:
                target.addSeparator()
            else:
                target.addAction(action)


    def _populate_dropdown_menus(self):
        """All the dropdown menu entries for the GUI, called by __init__()"""

        fileLoadAction = self.createAction("&Open...",
                                           self.cwidget.loadConfigFile,
                                           QKeySequence.Open,
                                           "Load an existing configuration file")
        fileSaveAction = self.createAction("&Save As...",
                                           self.cwidget.saveConfigFile,
                                           QKeySequence.Save,
                                           "Save configuration file")
        fileQuitAction = self.createAction("&Quit", self.close,
                                           "Ctrl+Q", "filequit",
                                           "Close the application")

        helpAboutAction = self.createAction("&About Titus",
                self.helpAbout)
        openManualAction = self.createAction("User Manual", self.openManual)

        fileMenu = self.menuBar().addMenu("&File")
        helpMenu = self.menuBar().addMenu("&Help")

        self.addActions(fileMenu, (fileLoadAction, fileSaveAction,
                                   None, fileQuitAction))
        self.addActions(helpMenu, (openManualAction, None, helpAboutAction))


    def openManual(self):
        """Launch a browser (or a new tab) and open the user manual in it"""
        #url = os.path.join(sys.path[0], 'docs', 'index.html')
        #webbrowser.open_new_tab(url)
        pass


    def helpAbout(self):
        if platform.system()=='Windows':
            pyversion = sys.winver
        else:
            pyversion = platform.python_version()
        QMessageBox.about(self, "About Titus",
                """<b>Titus the Usurper - </b> v %s
                <p>Copyright &copy; 2009 Ketterle group, MIT.
                All rights reserved.
                <p>This application can be used to control the
                registers of a USRP FPGA device.
                <p>Python %s - Qt %s - PyQt %s on %s""" % (
                __version__, pyversion,
                QT_VERSION_STR, PYQT_VERSION_STR, platform.system()))


def main():
    app = QApplication(sys.argv)
    app.setOrganizationName("Ketterle group, MIT")
    app.setOrganizationDomain("cua.mit.edu/ketterle_group/")
    app.setApplicationName("Titus")
    app.setWindowIcon(QIcon(":/TitusIcon.png"))

    form = MainWindow()
    form.show()
    app.exec_()


if __name__ == '__main__':
    main()

