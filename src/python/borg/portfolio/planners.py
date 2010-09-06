"""
@author: Bryan Silverthorn <bcs@cargo-cult.org>
"""

from abc         import (
    ABCMeta,
    abstractmethod,
    )
from cargo.log   import get_logger
from cargo.sugar import ABC

log = get_logger(__name__)

class AbstractPlanner(ABC):
    """
    Interface for action selection schemes.
    """

    @abstractmethod
    def select(self, model, history, budget, random):
        """
        Select an action.
        """

class HardMyopicPlanner(AbstractPlanner):
    """
    Deterministic greedy action selection.
    """

    def __init__(self, discount, enabled = None):
        """
        Initialize.
        """

        self._discount = discount
        self._enabled  = enabled

    def select(self, model, history, budget, random):
        """
        Select an action.
        """

        # compute next-step predictions
        predicted = model.predict(history, random)

        # select an apparently-best action
        from itertools import izip

        best_action      = None
        best_expectation = None

        for (i, action) in enumerate(model.actions):
            if self._enabled is None:
                on = True
            else:
                on = self._enabled[i]

            if on and action.cost <= budget:
                e  = sum(p * o.utility for (p, o) in izip(predicted[i], action.outcomes))
                e *= self._discount**action.cost

                if best_action is None or best_expectation < e:
                    best_action      = action
                    best_expectation = e

        return best_action

class BellmanPlanner(AbstractPlanner):
    """
    Fixed-horizon optimal replanning.
    """

    def __init__(self, horizon, discount, enabled = None):
        """
        Initialize.
        """

        self._horizon  = horizon
        self._discount = discount
        self._enabled  = enabled

    def select(self, model, history, budget, random):
        """
        Select an action.
        """

        from borg.portfolio.bellman import BellmanCore

        core = BellmanCore(model, self._discount, self._enabled)

        (utility, plan) = core.plan(self._horizon, budget, history)

        log.detail("computed Bellman plan: %s", " -> ".join(a.description for a in plan))

        return plan[0]

