import pyedflib
import numpy as np
edf_file_in="E:\D26 edf backup\D26 190125 COGAN_LEXICALDELAY_1.edf"
edf_file_out="E:\D26 edf backup\D26 190125 COGAN_LEXICALDELAY_test.edf"
mapping = data_dict = {
    'Event': 'Event', 'C1': 'RTG19', 'C2': 'RTG20', 'C3': 'RTG21', 'C4': 'RTG22', 'C5': 'RTG23',
    'C6': 'RTG24', 'C7': 'RTG27', 'C8': 'RTG28', 'C9': 'RTG29', 'C10': 'RTG30', 'C11': 'RTG31',
    'C12': 'RTG32', 'C13': 'RTG35', 'C14': 'RTG36', 'C15': 'RTG37', 'C16': 'RTG38', 'C17': 'RTG39',
    'C18': 'RTG40', 'C19': 'RTG43', 'C20': 'RTG44', 'C21': 'RTG45', 'C22': 'RTG46', 'C23': 'RTG47',
    'C24': 'RTG48', 'C25': 'RPG17', 'C26': 'RPG18', 'C27': 'RPG19', 'C28': 'RPG20', 'C29': 'RPG21',
    'C30': 'RPG22', 'C31': 'RPG23', 'C32': 'RPG24', 'C33': 'RPG25', 'C34': 'RPG26', 'C35': 'RPG27',
    'C36': 'RPG28', 'C37': 'RPG29', 'C38': 'RPF30', 'C39': 'RPG31', 'C40': 'RPG32', 'C41': 'RPG33',
    'C42': 'RPG34', 'C43': 'RPG35', 'C44': 'RPG36', 'C45': 'RPG37', 'C46': 'RPG38', 'C47': 'RPF39',
    'C48': 'RPG40', 'C49': 'RAT1', 'C50': 'RAT2', 'C51': 'RAT3', 'C52': 'RAT4', 'C53': 'RAST1',
    'C54': 'RAST2', 'C55': 'RAST3', 'C56': 'RAST4', 'C57': 'RPST1', 'C58': 'RPST2', 'C59': 'RPST3',
    'C60': 'RPST4', 'C61': 'EKGL', 'C62': 'EKGR', 'C63': 'C63', 'C64': 'C64', 'C65': 'C65',
    'C66': 'C66', 'C67': 'C67', 'C68': 'C68', 'C69': 'C69', 'C70': 'C70', 'C71': 'C71',
    'C72': 'C72', 'C73': 'C73', 'C74': 'C74', 'C75': 'C75', 'C76': 'C76', 'C77': 'C77',
    'C78': 'C78', 'C79': 'C79', 'C80': 'C80', 'C81': 'C81', 'C82': 'C82', 'C83': 'C83',
    'C84': 'C84', 'C85': 'C85', 'C86': 'C86', 'C87': 'C87', 'C88': 'C88', 'C89': 'C89',
    'C90': 'C90', 'C91': 'C91', 'C92': 'C92', 'C93': 'C93', 'C94': 'C94', 'C95': 'C95',
    'C96': 'C96', 'C97': 'C97', 'C98': 'C98', 'C99': 'C99', 'C100': 'C100', 'C101': 'C101',
    'C102': 'C102', 'C103': 'C103', 'C104': 'C104', 'C105': 'C105', 'C106': 'C106',
    'C107': 'C107', 'C108': 'C108', 'C109': 'C109', 'C110': 'C110', 'C111': 'C111',
    'C112': 'C112', 'C113': 'C113', 'C114': 'C114', 'C115': 'C115', 'C116': 'C116',
    'C117': 'C117', 'C118': 'C118', 'C119': 'C119', 'C120': 'C120', 'DC1': 'DC1', 'DC2': 'DC2',
    'DC3': 'DC3', 'DC4': 'DC4', 'DC5': 'DC5', 'DC6': 'DC6', 'DC7': 'DC7', 'DC8': 'DC8',
    'DC9': 'DC9', 'DC10': 'DC10', 'DC11': 'DC11', 'DC12': 'DC12', 'DC13': 'DC13', 'DC14': 'DC14',
    'DC15': 'DC15', 'DC16': 'DC16', 'TRIG': 'TRIG', 'OSAT': 'OSAT', 'PR': 'PR', 'Pleth': 'Pleth'
}
pyedflib.highlevel.rename_channels(edf_file_in, mapping, edf_file_out, verbose=True)