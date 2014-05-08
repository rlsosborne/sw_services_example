#include <platform.h>
#include <xs1.h>
#include <assert.h>

void configure_link(tileref tile, unsigned linkNum, unsigned direction,
                    int isFiveWire, unsigned intraTokenDelay,
                    unsigned interTokenDelay)
{
  assert(intraTokenDelay > 0 && interTokenDelay > 1);
  unsigned regVal;

  // Setup link direction.
  regVal = 0;
  regVal = XS1_LINK_DIRECTION_SET(regVal, direction);
  write_node_config_reg(tile, XS1_SSWITCH_SLINK_0_NUM + linkNum, regVal);

  // Say hello.
  regVal = 0;
  regVal = XS1_XLINK_INTRA_TOKEN_DELAY_SET(regVal, intraTokenDelay - 1);
  regVal = XS1_XLINK_INTER_TOKEN_DELAY_SET(regVal, interTokenDelay - 2);
  regVal = XS1_XLINK_WIDE_SET(regVal, isFiveWire);
  regVal = XS1_XLINK_ENABLE_SET(regVal, 1);
  regVal = XS1_XLINK_HELLO_SET(regVal, 1);
  write_node_config_reg(tile, XS1_SSWITCH_XLINK_0_NUM + linkNum, regVal);

  // Wait for someone to say hello to us.
  unsigned tmp;
  do {
    read_node_config_reg(tile, XS1_SSWITCH_XLINK_0_NUM + linkNum, tmp);
  } while (!XS1_RX_CREDIT(tmp));

  // Say hello again.
  write_node_config_reg(tile, XS1_SSWITCH_XLINK_0_NUM + linkNum, regVal);
}

void this_side(chanend c)
{
  int linknum;
#ifdef MASTER
  linknum = 1; // XLD
#else
  linknum = 0; // XLC
#endif
  configure_link(tile[0], linknum, 1, 0, 5, 5);
#ifdef MASTER
  c <: 0;
#else
  c :> int;
#endif
}

int main()
{
  chan c;
  par
  {
    other_side(c);
    on tile[0]: this_side(c);
  }
  return 0;
}

