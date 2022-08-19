/** Proof-of-concept to show different methods to load executables in the Linux kernel
 *
 * @copyright 2021, Steffen Vogel
 * @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 * @author    Steffen Vogel <post@steffenvogel.de>
 * @link      https://www.steffenvogel.de
 */

#include <linux/elf.h>
#include <linux/module.h>
#include <linux/string.h>
#include <linux/stat.h>
#include <linux/binfmts.h>
#include <linux/init.h>
#include <linux/file.h>
#include <linux/err.h>
#include <linux/fs.h>
#include <linux/module.h>	/* Needed by all modules */
#include <linux/kernel.h>	/* Needed for KERN_INFO */
#include <linux/init.h>		/* Needed for the macros */

#include <linux/fs.h>

static int load_binary(struct linux_binprm *bprm)
{
	int retval;
	const char *i_name, *i_arg;
	char interp[BINPRM_BUF_SIZE];
	struct file *file;
	struct elfhdr *hdr = (struct elfhdr *) bprm->buf;

	/* Check if this is an ELF file */
	if (memcmp(hdr->e_ident, ELFMAG, SELFMAG) != 0)
		return -ENOEXEC;
	if (hdr->e_type != ET_EXEC && hdr->e_type != ET_DYN)
		return -ENOEXEC;
	if (!elf_check_arch(hdr))
		return -ENOEXEC;
	if (!bprm->file->f_op->mmap)
		return -ENOEXEC;

	printk(KERN_INFO "Got ELF file in binfmt_hermit\n");

	if (hdr->e_ident[EI_OSABI] != 0xa1)
		return -ENOEXEC;

	/* Hardcoded for now */
	i_name = "/custom_loader_poc/proxy";
	i_arg = NULL;

	strcpy (interp, i_name);

	printk(KERN_INFO "It's a hermit one! Start the interpreter\n");

	/*
	 * OK, we've parsed out the interpreter name and
	 * (optional) argument.
	 * Splice in (1) the interpreter's name for argv[0]
	 *           (2) (optional) argument to interpreter
	 *           (3) filename of shell script (replace argv[0])
	 *
	 * This is done in reverse order, because of how the
	 * user environment and arguments are stored.
	 */
	retval = remove_arg_zero(bprm);
	if (retval)
		return retval;

	retval = copy_strings_kernel(1, &bprm->interp, bprm);
	if (retval < 0)
		return retval;

	bprm->argc++;

	retval = copy_strings_kernel(1, &i_name, bprm);
	if (retval)
		return retval;

	bprm->argc++;

	retval = bprm_change_interp(interp, bprm);
	if (retval < 0)
		return retval;

	/*
	 * OK, now restart the process with the interpreter's dentry.
	 */
	file = open_exec(interp);
	if (IS_ERR(file))
		return PTR_ERR(file);

	bprm->file = file;
	retval = prepare_binprm(bprm);
	if (retval < 0)
		return retval;

	return search_binary_handler(bprm);
}

static struct linux_binfmt script_format = {
        .module         = THIS_MODULE,
        .load_binary    = load_binary,
};

static int init(void)
{
	printk(KERN_INFO "Loaded binary format for HermitCore\n");

	register_binfmt(&script_format);

	return 0;
}

static void cleanup(void)
{
	printk(KERN_INFO "Un-loaded binary format for HermitCore\n");

	unregister_binfmt(&script_format);
}

module_init(init);
module_exit(cleanup);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Steffen Vogel <steffen.vogel@rwth-aachen.de>");
