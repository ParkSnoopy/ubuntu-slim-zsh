"""Load ordered topics from their own modules."""

import re
from importlib import import_module
from types import MappingProxyType

from contract import Topic
from settings import TOPIC_ORDER


def load_topics():
    catalog = {}
    for name in TOPIC_ORDER:
        module_name = name.replace("-", "_")
        module_name = re.sub(r"_(\d+)$", r"\1", module_name)
        module = import_module(f"topics.{module_name}")
        topic = module.TOPIC
        if not isinstance(topic, Topic) or topic.name != name:
            raise TypeError(f"Invalid topic declaration: {name}")
        catalog[name] = topic
    return MappingProxyType(catalog)


TOPICS = load_topics()
