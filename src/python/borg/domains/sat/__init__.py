"""@author: Bryan Silverthorn <bcs@cargo-cult.org>"""

import contextlib
import borg

from . import features
from . import instance
from . import solvers

class SatisfiabilityTask(object):
    def __init__(self, path):
        self.path = path

    def clean(self):
        pass

@borg.named_domain
class Satisfiability(object):
    name = "sat"
    extensions = ["*.cnf"]

    @contextlib.contextmanager
    def task_from_path(self, task_path):
        """Clean up cached task resources on context exit."""

        task = SatisfiabilityTask(task_path)

        yield task

        task.clean()

    def compute_features(self, task):
        return features.get_features_for(task.path)

    def is_final(self, task, answer):
        """Is the answer definitive for the task?"""

        return answer is not None

    def show_answer(self, task, answer):
        if answer is None:
            print "s UNKNOWN"

            return 0
        elif answer:
            print "s SATISFIABLE"
            print "v", " ".join(map(str, answer)), "0"

            return 10
        else:
            print "s UNSATISFIABLE"

            return 20

