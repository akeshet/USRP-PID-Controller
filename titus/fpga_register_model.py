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


import os
import time

from PyQt4.QtCore import *
from PyQt4.QtGui import *


ADDRESS, NAME, MINVALUE, MAXVALUE, VALUE, VALUESTR = range(6)


class Register(object):

    def __init__(self, address, name, maxvalue, minvalue, value, nametype,
                 valuelist):
        self.address = address
        self.name = QString(name)
        self.minvalue = minvalue
        if nametype:
            self.maxvalue = len(valuelist) - 1
            self.valuestr = valuelist[0]
        else:
            self.maxvalue = maxvalue
            self.valuestr = u""
        self.value = value
        self.nametype = nametype
        self.valuelist = valuelist


    def set_register(self):
        """Set the register with the current value."""
	writeValue = self.value;
	if writeValue<0:
		writeValue = 4294967296 + writeValue;

        os.system('usrper write_fpga_reg %s %s'%(self.address, writeValue))


class RegisterTableModel(QAbstractTableModel):

    def __init__(self):
        super(RegisterTableModel, self).__init__()
        self.dirty = False
        self.registers = []


    def flags(self, index):
        """Determines which fields are selectable and/or editable."""

        # not editable
        if not index.isValid() or index.column() < 4:
            return Qt.ItemIsEnabled
        # selectable but not editable
        elif not self.registers[index.row()].nametype and \
             index.column()==VALUESTR:
            return QAbstractTableModel.flags(self, index)
        # selectable but not editable
        elif self.registers[index.row()].nametype and index.column()==VALUE:
            return QAbstractTableModel.flags(self, index)
        return Qt.ItemFlags(QAbstractTableModel.flags(self, index)|
                            Qt.ItemIsEditable)


    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self.registers)):
            return QVariant()
        register = self.registers[index.row()]
        column = index.column()
        if role == Qt.DisplayRole:
            if column == ADDRESS:
                return QVariant(register.address)
            if column == NAME:
                return QVariant(register.name)
            elif column == MINVALUE:
                return QVariant(register.minvalue)
            elif column == MAXVALUE:
                return QVariant(register.maxvalue)
            elif column == VALUE:
                return QVariant(register.value)
            elif column == VALUESTR:
                return QVariant(register.valuestr)
        #elif role == Qt.TextAlignmentRole:
            #if column in [ADDRESS, NAME, MINVALUE, MAXVALUE, VALUE, VALUESTR]:
                #return QVariant(int(Qt.AlignRight|Qt.AlignVCenter))
            #return QVariant(int(Qt.AlignLeft|Qt.AlignVCenter))

        return QVariant()


    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if role == Qt.TextAlignmentRole:
            if orientation == Qt.Horizontal:
                return QVariant(int(Qt.AlignLeft|Qt.AlignVCenter))
            return QVariant(int(Qt.AlignRight|Qt.AlignVCenter))
        if role != Qt.DisplayRole:
            return QVariant()
        if orientation == Qt.Horizontal:
            if section == ADDRESS:
                return QVariant("Address")
            if section == NAME:
                return QVariant("Name")
            elif section == MINVALUE:
                return QVariant("Min Value")
            elif section == MAXVALUE:
                return QVariant("Max Value")
            elif section == VALUE:
                return QVariant("Value")
            elif section == VALUESTR:
                return QVariant("Value string")
        return QVariant(int(section + 1))


    def rowCount(self, index=QModelIndex()):
        return len(self.registers)


    def columnCount(self, index=QModelIndex()):
        return 6


    def setData(self, index, value, role=Qt.EditRole):
        if index.isValid() and 0 <= index.row() < len(self.registers) \
           and index.column() in [4, 5]:
            register = self.registers[index.row()]
            column = index.column()
            if column == VALUE:
                value, ok = value.toInt()
                if ok:
                    register.value = value
            elif column == VALUESTR:
                value, ok = value.toInt()
                if ok:
                    register.value = value
                register.valuestr = register.valuelist[value]
            self.dirty = True
            register.set_register()
            self.emit(SIGNAL("dataChanged(QModelIndex,QModelIndex)"),
                      index, index)
            return True
        return False


    def load(self, filename):
        exception = None
        fileobj = None
        try:
            if not filename:
                raise IOError, "no filename specified for loading"
            fileobj = file(filename, 'r')
            lines = fileobj.readlines()
            if len(lines)==len(self.registers):
                for line, register in zip(lines, self.registers):
                    value = int(line.split()[1])
                    register.value = value
                    if register.nametype:
                        register.valuestr = register.valuelist[value]
            else:
                raise ValueError, "length of file is incorrect"
            self.dirty = False
            # set all FPGA registers
            self.set_registers()
        except IOError, e:
            exception = e
        finally:
            if fileobj is not None:
                fileobj.close()
            if exception is not None:
                raise exception


    def save(self, filename):
        exception = None
        fileobj = None
        try:
            if not filename:
                raise IOError, "no filename specified for saving"
            fileobj = file(filename, 'w')
            for register in self.registers:
                fileobj.write("".join([str(register.address), ",  ",
                                       str(register.value), "\n"]))
            self.dirty = False
        except IOError, e:
            exception = e
        finally:
            if fileobj is not None:
                fileobj.close()
            if exception is not None:
                raise exception


    def set_registers(self):
        """Set all FPGA registers."""
        for num, register in enumerate(self.registers):
            register.set_register()
            # emit signal that says what register was just set
            self.emit(SIGNAL("registerSet"), num)


    def allzero(self):
        """Set all register values (and valuestr's) to zero."""
        for register in self.registers:
            register.value = 0
            if register.nametype:
                register.valuestr = register.valuelist[0]


class RegisterDelegate(QItemDelegate):

    def __init__(self, parent=None):
        super(RegisterDelegate, self).__init__(parent)


    def createEditor(self, parent, option, index):
        if index.column() == VALUE:
            spinbox = QSpinBox(parent)
            spinbox.setAlignment(Qt.AlignRight | Qt.AlignVCenter)
            return spinbox
        elif index.column() == VALUESTR:
            combobox = QComboBox(parent)
            return combobox
        else:
            return QItemDelegate.createEditor(self, parent, option, index)


    def setEditorData(self, editor, index):
        register = index.model().registers[index.row()]
        if index.column() == VALUE:
            min, max = (register.minvalue, register.maxvalue)
            editor.setRange(min, max)
            editor.setValue(register.value)
        elif index.column() == VALUESTR:
            editor.addItems(register.valuelist)
            editor.setCurrentIndex(register.value)
        else:
            return QItemDelegate.createEditor(self, parent, option, index)


    def setModelData(self, editor, model, index):
        if index.column() == VALUE:
            model.setData(index, QVariant(editor.value()))
        elif index.column() == VALUESTR:
            model.setData(index, QVariant(editor.currentIndex()))
        else:
            QItemDelegate.setModelData(self, editor, model, index)


maxGain = 2**20 - 1
minGain = -2**20
maxPhase = 31
minPhase = -32
maxMixerGain = 2**15 - 1
minMixerGain = -2**15
dacOutputBitDepth = 14


def generate_registers():
    for address, name, maxvalue, minvalue, nametype, valuelist in (

# PID Gain registers
(65, "PA", maxGain, minGain, False, None),
(66, "IA", maxGain, minGain, False, None),
(67, "DA", maxGain, minGain, False, None),
(68, "PB", maxGain, minGain, False, None),
(69, "IB", maxGain, minGain, False, None),
(70, "DB", maxGain, minGain, False, None),
(71, "PC", maxGain, minGain, False, None),
(72, "IC", maxGain, minGain, False, None),
(73, "DC", maxGain, minGain, False, None),
(74, "PD", maxGain, minGain, False, None),
(75, "ID", maxGain, minGain, False, None),
(76, "DD", maxGain, minGain, False, None),

(77, "Mixer 1 Phase", maxPhase, minPhase, False, None),
(78, "Mixer 2 Phase", maxPhase, minPhase, False, None),
(79, "Mixer 3 Phase", maxPhase, minPhase, False, None),
(80, "Mixer 4 Phase", maxPhase, minPhase, False, None),

(81, "Mixer 1 Gain", maxMixerGain, minMixerGain, False, None),
(82, "Mixer 2 Gain", maxMixerGain, minMixerGain, False, None),
(83, "Mixer 3 Gain", maxMixerGain, minMixerGain, False, None),
(84, "Mixer 4 Gain", maxMixerGain, minMixerGain, False, None),

(85, "Triangle Generator Max", 2**(dacOutputBitDepth-1)-1, -2**(dacOutputBitDepth-1), False, None),
(86, "Triangle Generator Min", 2**(dacOutputBitDepth - 1)-1, -2**(dacOutputBitDepth-1), False, None),
(87, "Triangle Generator Step Size", 2**31-1, -2**31, False, None),

# output muxes
(88, "Output 1 Selector", 0, 0, True, ["PID 1",
                                       "Triangle Wave",
                                       "Input 1 Loopback",
                                       "Zero"]),
(89, "Output 2 Selector", 0, 0, True, ["PID 2",
                                       "Triangle Wave",
                                       "Input 2 Loopback",
                                       "Zero"]),
(90, "Output 3 Selector", 0, 0, True, ["PID 3",
                                       "Triangle Wave",
                                       "Input 3 Loopback",
                                       "Zero"]),
(91, "Output 4 Selector", 0, 0, True, ["Mixer 1",
                                       "Mixer 2",
                                       "Mixer 3",
                                       "N/A",
                                       "Lin. comb. 1",
                                       "Lin. comb. 2",
                                       "Lin. comb. 3",
                                       "Lin. comb. 4",
                                       "Input 1 > threshold?",
                                       "Input 2 > threshold?",
                                       "Input 3 > threshold?",
                                       "Input 4 > threshold?",
                                       "Input 1 Loopback",
                                       "Input 2 Loopback",
                                       "Input 3 Loopback",
                                       "Input 4 Loopback",
                                       "Threshold 1",
                                       "Threshold 2",
                                       "Threshold 3",
                                       "Threshold 4",
                                       "Triangle Wave",
                                       "Zero",
                                       "Maximum",
                                       "Minimum",
                                       "PID 1",
                                       "PID 2",
                                       "PID 3",
                                       "PID 4",
                                       "genreg1",
                                       "genreg2",
                                       "genreg3",
                                       "genreg4"]),

# Linear combination modules
(92, "Lin. comb 1, gain 1", maxGain, minGain, False, None),
(93, "Lin. comb 1, gain 2", maxGain, minGain, False, None),
(94, "Lin. comb 2, gain 1", maxGain, minGain, False, None),
(95, "Lin. comb 2, gain 2", maxGain, minGain, False, None),
(96, "Lin. comb 3, gain 1", maxGain, minGain, False, None),
(97, "Lin. comb 3, gain 2", maxGain, minGain, False, None),

# Thresholds
(100, "Threshold 1", 2**11-1, -2**11, False, None),
(101, "Threshold 2", 2**11-1, -2**11, False, None),
(102, "Threshold 3", 2**11-1, -2**11, False, None),
(103, "Threshold 4", 2**11-1, -2**11, False, None),

# Program state register
(104, "Run Program", 0, 0, True, ["Idle",
                                  "Idle",
                                  "Lockscan 1",
                                  "Lockscan 2"]),

(105, "PID 1 Input", 0, 0, True, ["Mixer 1",
                                  "Mixer 1",
                                  "Mixer 2",
                                  "Mixer 3",
                                  "Mixer 4",
                                  "Lin. comb. 1",
                                  "Lin. comb 2",
                                  "Lin. comb 3",
                                  "N/A",
                                  "Input 1",
                                  "Input 2",
                                  "Input 3",
                                  "Input 4",
                                  "Triangle Wave"
                                  ]),

(106, "PID 2 Input", 0, 0, True, ["Mixer 2",
                                  "Mixer 1",
                                  "Mixer 2",
                                  "Mixer 3",
                                  "Mixer 4",
                                  "Lin. comb. 1",
                                  "Lin. comb 2",
                                  "Lin. comb 3",
                                  "N/A",
                                  "Input 1",
                                  "Input 2",
                                  "Input 3",
                                  "Input 4",
                                  "Triangle Wave"
                                  ]),

(107, "PID 3 Input", 0, 0, True, ["Mixer 3",
                                  "Mixer 1",
                                  "Mixer 2",
                                  "Mixer 3",
                                  "Mixer 4",
                                  "Lin. comb. 1",
                                  "Lin. comb 2",
                                  "Lin. comb 3",
                                  "N/A",
                                  "Input 1",
                                  "Input 2",
                                  "Input 3",
                                  "Input 4",
                                  "Triangle Wave"
                                  ]),

(108, "PID 4 Input", 0, 0, True, ["Mixer 4",
                                  "Mixer 1",
                                  "Mixer 2",
                                  "Mixer 3",
                                  "Mixer 4",
                                  "Lin. comb. 1",
                                  "Lin. comb. 2",
                                  "Lin. comb. 3",
                                  "N/A",
                                  "Input 1",
                                  "Input 2",
                                  "Input 3",
                                  "Input 4"                                  
                                  ]),

# lin comb input muxes
(109, "Lin. comb. 1 input 1", 0, 0, True, ["Mixer 1",
                                           "Mixer 2",
                                           "Mixer 3",
                                           "Mixer 4",
                                           "Input 1",
                                           "Input 2",
                                           "Input 3",
                                           "Input 4",
                                           "genreg1",
                                           "genreg2",
                                           "genreg3",
                                           "genreg4",
                                           "Triangle Wave"
                                           ]),

(110, "Lin. comb. 1 input 2", 0, 0, True, ["Mixer 1",
                                           "Mixer 2",
                                           "Mixer 3",
                                           "Mixer 4",
                                           "Input 1",
                                           "Input 2",
                                           "Input 3",
                                           "Input 4",
                                           "genreg1",
                                           "genreg2",
                                           "genreg3",
                                           "genreg4",
                                           "Triangle Wave"]),

(111, "Lin. comb. 2 input 1", 0, 0, True, ["Mixer 1",
                                           "Mixer 2",
                                           "Mixer 3",
                                           "Mixer 4",
                                           "Input 1",
                                           "Input 2",
                                           "Input 3",
                                           "Input 4",
                                           "genreg1",
                                           "genreg2",
                                           "genreg3",
                                           "genreg4",
                                           "Triangle Wave"]),

(112, "Lin. comb. 2 input 2", 0, 0, True, ["Mixer 1",
                                           "Mixer 2",
                                           "Mixer 3",
                                           "Mixer 4",
                                           "Input 1",
                                           "Input 2",
                                           "Input 3",
                                           "Input 4",
                                           "genreg1",
                                           "genreg2",
                                           "genreg3",
                                           "genreg4",
                                           "Triangle Wave"]),

(113, "Enable 1MHz Oscillator", 0, 0, True, ["Yes",
                                             "No"]),

(114, "Lin. comb. 1 input 2 gated?", 0, 0, True, ["No",
                                                  "Yes"]),

(115, "Lin. comb. 2 input 2 gated?", 0, 0, True, ["No",
                                                  "Yes"]),
(116, "genreg1 (General purpose register)", 2**(31)-1, -2**(31), False, None),
(117, "genreg2", 2**(31)-1, -2**(31), False, None),
(118, "genreg3", 2**(31)-1, -2**(31), False, None),
(119, "genreg4", 2**(31)-1, -2**(31), False, None),
(120, "PID 1 Autoactivate", 0, 0, True, ["Never",
                                        "Always",
                                        "Input 1 > threshold?",
                                        "Input 2 > threshold?",
                                        "Input 3 > threshold?",
                                        "Input 4 > threshold?",
                                        "Input 1 < threshold?",
                                        "Input 2 < threshold?",
                                        "Input 3 < threshold?",
                                        "Input 4 < threshold?"]),

(121, "PID 2 Autoactivate", 0, 0, True, ["Never",
                                        "Always",
                                        "Input 1 > threshold?",
                                        "Input 2 > threshold?",
                                        "Input 3 > threshold?",
                                        "Input 4 > threshold?",
                                        "Input 1 < threshold?",
                                        "Input 2 < threshold?",
                                        "Input 3 < threshold?",
                                        "Input 4 < threshold?"]),

(122, "N/A", 0, 0, False, None),
(123, "N/A", 0, 0, False, None)
):
        yield Register(address, name, maxvalue, minvalue, 0,
                       nametype, valuelist)
