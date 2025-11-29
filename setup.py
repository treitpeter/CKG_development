import setuptools
from setuptools import setup
from setuptools.command.develop import develop
from setuptools.command.install import install
from subprocess import check_call
import ckg.init
import os

# Check if README.md exists, otherwise fallback
if os.path.exists("README.md"):
    with open("README.md", "r") as fh:
        long_description = fh.read()
    long_description_content_type = 'text/markdown'
else:
    long_description = "Clinical Knowledge Graph"
    long_description_content_type = 'text/plain'

class PreInstallCommand(install):
    """Pre-installation for install mode."""
    def run(self):
        # Use modern requirements if available
        req_file = "requirements_modern.txt" if os.path.exists("requirements_modern.txt") else "requirements.txt"
        if os.path.exists(req_file):
            check_call(f"pip install -r {req_file}".split())
        # ckg.init.installer_script() # clean this up?
        install.run(self)

class PreDevelopCommand(develop):
    """Pre-installation for install mode."""
    def run(self):
        req_file = "requirements_modern.txt" if os.path.exists("requirements_modern.txt") else "requirements.txt"
        if os.path.exists(req_file):
            check_call(f"pip install -r {req_file}".split())
        # ckg.init.installer_script()
        develop.run(self)


setuptools.setup(
    name="CKG", 
    version="2.0.0",
    author="Alberto Santos Delgado, Peter, Gemini",
    author_email="alberto.santos@sund.ku.dk",
    description="Clinical Knowledge Graph (Clemini Edition) - Modernized for Python 3.10+ and Neo4j 5.x",
    long_description=long_description,
    long_description_content_type=long_description_content_type,
    url="https://github.com/treitpeter/CKG",
    packages=setuptools.find_packages(),
    cmdclass={
        'develop': PreDevelopCommand,
        'install': PreInstallCommand,
    },
    entry_points={'console_scripts': [
        'ckg_app=ckg.report_manager.index:main',
        'ckg_debug=ckg.debug:main',
        'ckg_build=ckg.graphdb_builder.builder.builder:run_full_update',
        'ckg_update_textmining=ckg.graphdb_builder.builder.builder:update_textmining']},
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.10',
    include_package_data=True,
)
