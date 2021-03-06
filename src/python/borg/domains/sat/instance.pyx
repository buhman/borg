"""@author: Bryan Silverthorn <bcs@cargo-cult.org>"""

import numpy
import scipy.sparse

cimport numpy

class SAT_Instance(object):
    """Read a SAT instance in DIMACS format."""

    def __init__(self, constraints):
        self.constraints = constraints
        (self.M, self.N) = constraints.shape

    def write(self, out_file):
        """Write this CNF to a file, in DIMACS format."""

        out_file.write("p cnf {0} {1}\n".format(self.N, len(self.clauses)))

        for clause in self.clauses:
            out_file.write(" ".join(clause))
            out_file.write(" 0\n")

    #def satisfied(self, certificate):
        #"""Verify that the certificate satisfies this expression."""

        #assignment = numpy.ones(self.N, bool)

        #for literal in certificate:
            #variable = abs(literal) - 1

            #if literal == 0:
                #break
            #elif variable >= assignment.size:
                #return None

            #assignment[variable] = literal > 0

        #for clause in self.clauses:
            #satisfied = False

            #for literal in clause:
                #if assignment[abs(literal)] == literal > 0:
                    #satisfied = True

                    #break

            #if not satisfied:
                #return None

        #return assignment

cdef class DIMACS_Lexer(object):
    cdef bytes _text
    cdef char* _p
    cdef char* _q

    def __init__(self, text):
        self._text = text
        self._p = self._text
        self._q = self._p

    cdef bytes lex(self):
        while self._q[0] == ' ' and self._q[0] != '\0':
            self._q += 1

        if self._q[0] == '\n':
            self._p = self._q
            self._q += 1
        elif self._q[0] == '\0':
            self._p = self._q
        else:
            self._p = self._q

            while self._q[0] != " " and self._q[0] != "\n" and self._q[0] != "\0":
                self._q += 1

        if self._p == self._q:
            return None
        else:
            return self._p[:self._q - self._p]

cdef class DIMACS_Parser(object):
    cdef DIMACS_Lexer _lexer
    cdef list _csr_data
    cdef list _csr_indices
    cdef list _csr_indptrs

    def parse(self, text):
        self._lexer = DIMACS_Lexer(text)
        self._csr_data = []
        self._csr_indices = []
        self._csr_indptrs = [0]

        while True:
            token = self._lexer.lex()

            if len(token) == 0:
                return
            elif token[0] == "c":
                self.parse_comment()
            elif token[0] == "p":
                (kind, N, M) = self.parse_header()

                break

        if kind == "cnf":
            while self.parse_constraint():
                pass
        else:
            raise RuntimeError("unknown instance type")

        constraints = \
            scipy.sparse.csr_matrix(
                (self._csr_data, self._csr_indices, self._csr_indptrs),
                shape = (M, N),
                dtype = numpy.int8,
                )

        return SAT_Instance(constraints)

    cdef parse_comment(self):
        while True:
            token = self._lexer.lex()

            if len(token) == 0 or token[0] == "\n":
                break

    cdef parse_header(self):
        kind = self._lexer.lex()
        N = int(self._lexer.lex())
        M = int(self._lexer.lex())

        return (kind, N, M)

    cdef int parse_constraint(self):
        cdef char* token
        cdef int literal

        while True:
            str_token = self._lexer.lex()

            if str_token is None:
                return False
            else:
                token = str_token

                if token[0] == "0":
                    self._csr_indptrs.append(len(self._csr_data))

                    return True
                elif token[0] != "\n":
                    literal = int(str_token)

                    if literal > 0:
                        value = 1
                    else:
                        value = -1

                    self._csr_data.append(value)
                    self._csr_indices.append(abs(literal) - 1)

def parse_sat_file(task_file):
    return DIMACS_Parser().parse(task_file.read())

