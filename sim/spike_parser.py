def parse_spike_log_file(filename):
    results = []
    regs = {}
    with open(filename) as file:
        for line in file:
            if line.startswith('core'):
                cmd_with_operands = line.replace(',', '').split()[4:]
                cmd = cmd_with_operands[0]
                if cmd == 'ret':
                    return results
            else:
                if 'reg' in line:
                    regs = {}
                if 'zero' in line:
                    args = line.replace(':', '').split()
                    regs['zero'] = args[1]
                    regs['ra'] = args[3]
                    regs['sp'] = args[5]
                    regs['gp'] = args[7]
                if 'tp' in line:
                    args = line.replace(':', '').split()
                    regs['tp'] = args[1]
                    regs['t0'] = args[3]
                    regs['t1'] = args[5]
                    regs['t2'] = args[7]
                if 's0' in line:
                    args = line.replace(':', '').split()
                    regs['s0'] = args[1]
                    regs['s1'] = args[3]
                    regs['a0'] = args[5]
                    regs['a1'] = args[7]
                if 'a2' in line:
                    args = line.replace(':', '').split()
                    regs['a2'] = args[1]
                    regs['a3'] = args[3]
                    regs['a4'] = args[5]
                    regs['a5'] = args[7]
                if 'a6' in line:
                    args = line.replace(':', '').split()
                    regs['a6'] = args[1]
                    regs['a7'] = args[3]
                    regs['s2'] = args[5]
                    regs['s3'] = args[7]
                if 's4' in line:
                    args = line.replace(':', '').split()
                    regs['s4'] = args[1]
                    regs['s5'] = args[3]
                    regs['s6'] = args[5]
                    regs['s7'] = args[7]              
                if 's8' in line:
                    args = line.replace(':', '').split()
                    regs['s8'] = args[1]
                    regs['s9'] = args[3]
                    regs['s10'] = args[5]
                    regs['s11'] = args[7]
                if 't3' in line:
                    args = line.replace(':', '').split()
                    regs['t3'] = args[1]
                    regs['t4'] = args[3]
                    regs['t5'] = args[5]
                    regs['t6'] = args[7]
                    if cmd == 'lw' or cmd == 'sw':
                        value = int(regs[cmd_with_operands[1]][2:], 16) 
                        op2 = cmd_with_operands[2]
                        op2 = op2.split('(')
                        op2_reg = regs[op2[1][:-1]]
                        address = int(op2[0]) + int(op2_reg[2:], 16)
                        results.append(
                            {
                                "comand": cmd,
                                "address": address,
                                "value": value
                            }
                        )
                        regs = {}
if __name__ == "__main__":
    parsed = parse_spike_log_file("spike_log.log")