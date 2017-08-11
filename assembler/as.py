#!/usr/bin/env python3

''' This is a 'simple' assembler for the Nanda Devi CPU.
    It is a clear example of how not to implement an assembler.
    Honestly: Don't do it this way.
    Nevertheless, it gets the job done. For now.

    The concept behind this is the following:
     * The lines of the input file are parsed, being divided into 
       mnemonic and arguments. Everything else is dropped.
     * For every mnemonic, there should be a function to generate
       an opcode from the mnemonic and its arguments.
     * These handler functions are wrapped in handler classes, each of
       which can be responsible for several mnemonics.
     * The handler functions generate 32-char strings of 1s and 0s,
       which represent the 32-bit opcode. This representation is quite
       flexible and allows the opcode to be build up step by step.
     * The assembler class pulls all the handlers together. It calls
       the correct one based on the mnemonic. This class also
       splits lines into mnemoincs and arguments and (on the side)
       handles labels.

'''

import sys

def check_reg(inp):
    if type(inp) != str or len(inp) != 5:
        return False
    for b in inp:
        if not b in '01':
            return False
    return True

def assert_reg(reg):
    if not check_reg(reg):
        raise Exception('Illegal register value: '+str(reg))

class instr_handler(object):

    def __init__(self):
        self.supported = [] # list of supported mnemonics

    def get_supported(self):
        return(self.supported)

    def handle(self, mnemonic, dest, src0, src1):
        raise Exception('Missing handle() implementation!')

instr_group = { 'load_immediate' : '00000',
                'alu'            : '00001',
                'mvcp'           : '00010',  # move and copy
                'condfc'         : '00011' } # conditional flow control

class instr_handler_ldi(instr_handler):

    def __init__(self):
        self.supported = ['ldi']

    def handle (self, mnemonic, dest, const):
        assert_reg(dest)
        assert mnemonic in self.supported
        assert type(const) == int
        assert const < 2**32
        assert const >= -2**31
        if const < 0:
            const += 2**32 # two's complement

        binrep = '{:032b}'.format(const)

        extend = binrep[0] # This also handles the special case
                           # of a positive 32 bit number which has
                           # the msb set.

        # Now for the division into value and shift:
        value = binrep
        shift = 0

        while len(value) > 17:
            # Remove the leading 0/1s, but leave one
            if value[0] == value[1] == extend:
                value = value[1:]
            # After that, remove zeros from the right
            elif value[-1] == '0':
                value = value[:-1]
                shift += 1
            else:
                raise Exception('ldi constant not representable!')

        # Make sure we actually calculated the correct value and
        # shift.
        assert len(value) == 17
        read_extend = value[0]
        read_constant = read_extend*(15-shift)+value+'0'*shift
        assert read_constant == binrep
        assert 0 <= shift <= 15

        instr = instr_group['load_immediate']
        instr += '0'
        instr += '{:04b}'.format(shift)
        instr += value
        instr += dest

        return(instr)

class instr_handler_alu(instr_handler):

    def __init__(self):
        self.alu_ops = { 'add'  : '00000',
                         'sub'  : '00001',
                         'addc' : '00010',
                         'subc' : '00011',
                         'or'   : '00100',
                         'xor'  : '00101',
                         'and'  : '00110',
                         'not'  : '00111',
                         'sll'  : '01000',
                         'slr'  : '01001',
                         'tst'  : '01010' }
        # list of supported mnemonics
        self.supported = [key for key in self.alu_ops]

    def handle(self, mnemonic, arg0=None, arg1=None, arg2=None):
        assert_reg(arg0)
        assert mnemonic in self.supported
        instr = instr_group['alu']
        instr += '0'*7
        instr += self.alu_ops[mnemonic]
        if mnemonic in ['not', 'tst']:
            instr += '00000'
            instr += arg0
        else:
            assert_reg(arg1)
            assert_reg(arg2)
            instr += arg2
            instr += arg1
        if mnemonic == 'tst':
            instr += '11111'
        else:
            instr += arg0
        return(instr)
        
class instr_handler_mvcp(instr_handler):

    def __init__(self):
        self.supported = ['mv', 'ldm', 'stm']

    def handle(self, mnemonic, dest, src):
        assert_reg(dest)
        assert_reg(src)
        assert mnemonic in self.supported
        instr = instr_group['mvcp']
        instr += '0'*10
        if mnemonic == 'mv':
            instr += '0'*7
            instr += src
            instr += dest
        elif mnemonic == 'ldm':
            instr += '01'
            instr += src
            instr += '0'*5
            instr += dest
        elif mnemonic == 'stm':
            instr += '10'
            instr += dest
            instr += src
            instr += '1'*5
        return(instr)

class instr_handler_condfc(instr_handler):

    def __init__(self):
        self.fc_ops = { 'scs' : '0001',
                        'scc' : '1001',
                        'szs' : '0010',
                        'szc' : '1010',
                        'sns' : '0100',
                        'snc' : '1100' }
        self.supported = [key for key in self.fc_ops]

    def handle(self, mnemonic):
        assert mnemonic in self.supported
        instr = instr_group['condfc']
        instr += '0'*18
        instr += self.fc_ops[mnemonic]
        instr += '1'*5
        return(instr)

labels = {}

class assembler:
    ''' The assembler class 'only' creates the opcodes for a given
        instruction.
    '''
    def __init__(self):
        self.handlers = {}
        self.address = 0
        self.linenum = 1
        self.outp_lines = []
        self.unresolved = [] # Lines with unresolved labels

    def register(self, handler):
        for mnemonic in handler.get_supported():
            self.handlers[mnemonic] = handler

    def handle_instr(self, instr):
        # instr is assumed to come in as an array
        # of [mnemonic, arg0, arg1, arg2]
        if not instr[0] in self.handlers:
            return(None)
        else:
            handler = self.handlers[instr[0]]
            args = [instr[0]]
            for arg in instr[1:]:
                decoded = decode_arg(arg)
                if decoded == 'unknown_label':
                    return(decoded)
                if arg != None:
                    args.append(decoded)

            # If this fails, the arguments are probably in the wrong
            # order or their number isn't correct.
            opcode_binstr = handler.handle(*args)

            assert len(opcode_binstr) == 32
            opcode = int(opcode_binstr, 2)
            return(opcode)

    def handle_line(self, line):
        line_orig = line
        if ';' in line:
            # Drop dat comment
            line = line[:line.find(';')]
        line = line.strip() #No leading or trailing whitespace
        if line.startswith('@'):
            # Save address of label
            label = line[:line.find(':')]
            labels[label] = self.address
            return(None)
        # Prepare splitting by whitespace:
        line = line.replace(',', ', ')
        split = line.split(' ')
        # Remove empty substrings:
        split = [s for s in split if s != '']
        # Remove ',' from substrings:
        split = [s.replace(',', '') for s in split]
        if len(split) == 0:
            return(None)

        opcode = asm.handle_instr(split)
        if opcode != None:
            if opcode == 'unknown_label':
                resline = '' # Add empty line that gets filled up once
                             # all labels are available.
                # Save the linenumber, line, its destination and address
                # for resolving the label later
                self.unresolved.append((self.linenum, line_orig,
                                        self.address, len(self.outp_lines)))
            else:
                resline = ('{:08x} '.format(opcode) +
                           '{:04x} '.format(self.address) +
                           line_orig.strip())
            return(resline)
        else:
            return(None)

    def add_line(self, line):
        try:
            resline = self.handle_line(line)
            if resline != None:
                self.outp_lines.append(resline)
                self.address += 4
        except Exception:
            print('Error in line ', self.linenum, ': ', line, sep='')
            raise
        self.linenum += 1

    def resolve_labels(self):
        try:
            for unresolved in self.unresolved:
                self.linenum = unresolved[0]
                self.address = unresolved[2]
                line = unresolved[1]
                resline = self.handle_line(line)
                if resline == None:
                    raise Exception('Unable to resolve label?')
                else:
                    self.outp_lines[unresolved[3]] = resline
        except Exception:
            print('Error in line ', self.linenum, ': ', line, sep='')
            raise

def decode_arg(arg):
    # Is it a register?
    if arg.startswith('r'):
        # General purpose register
        regnum = int(arg[1:])
        assert 0 <= regnum <= 15
        return('{:05b}'.format(regnum))
    if arg == 'pc':
        return('10000')
    if arg == 'sp':
        return('10001')
    if arg == 'flags':
        return('10010')
    if arg == 'drop':
        return('11111')

    # Or is it a constant?
    positive = 1
    if arg[0] == '-':
        arg = arg[1:]
        positive = -1
    if arg.startswith('0x'):
        return(positive*int(arg[2:], 16))
    if arg.startswith('0b'):
        return(positive*int(arg[2:], 2))
    if arg[0] in '0123456789':
        return(positive*int(arg))

    # Special case of constant: Label
    if arg[0] == '@':
        if arg in labels:
            return(labels[arg])
        else:
            # Label is not yet available
            return('unknown_label')

    # Unknown:
    return(None)


if __name__ == '__main__':
    if len(sys.argv) == 3:
        destfile = sys.argv[2]
    elif len(sys.argv) == 2:
        destfile = sys.argv[1]+'.hex'
    else:
        print('Usage:', sys.argv[0], 'sourefile [destfile]')
        exit()
    sourcefile = sys.argv[1]

    # Prepare assember
    asm = assembler()
    asm.register(instr_handler_ldi())
    asm.register(instr_handler_alu())
    asm.register(instr_handler_mvcp())
    asm.register(instr_handler_condfc())

    with open(sourcefile, 'r') as f:
        for line in f:
            asm.add_line(line)
    asm.resolve_labels()

    with open(destfile, 'w') as f:
        f.writelines('\n'.join(asm.outp_lines)+'\n')

