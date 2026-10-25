import type { ReactNode } from "react";
import Link from "@docusaurus/Link";
import useBaseUrl from "@docusaurus/useBaseUrl";
import Heading from "@theme/Heading";
import Layout from "@theme/Layout";
import BottleList from "@site/src/components/BottleList";
import Copyable from "@site/src/components/Copyable";
import Mascot from "@site/src/components/Mascot";
import styles from "./index.module.css";

const INSTALL = `brew tap macos-intel/tap
brew trust macos-intel/tap
brew install macos-intel/tap/cmake`;

type RowProps = { id: string; title: string; children: ReactNode };

// One brew.sh section: a centred emoji heading over a two-column row.
function Row({ id, title, children }: RowProps): ReactNode {
  return (
    <section className={styles.row}>
      <Heading as="h2" id={id} className={styles.rowTitle}>
        {title}
      </Heading>
      {children}
    </section>
  );
}

function Header(): ReactNode {
  return (
    <header className={styles.header}>
      <div className={styles.brand}>
        <img
          src={useBaseUrl("/homebrew-intel.svg")}
          alt="macOS Homebrew Intel logo: a beer mug with the Intel logo in its foam"
          width={96}
          height={114}
        />
        <h1>macOS Homebrew Intel</h1>
      </div>
      <p className={styles.subtitle}>Working to keep macOS Intel Brew builds maintained.</p>
      <p className={styles.support}>
        For Intel Macs on macOS Sequoia 15. Tahoe 26 support is planned. Not
        affiliated with or endorsed by Homebrew.
      </p>
    </header>
  );
}

export default function Home(): ReactNode {
  return (
    <Layout description="A Homebrew tap that keeps Intel Macs usable: prebuilt Sequoia bottles you pour instead of compile.">
      <main className={styles.wrap}>
        <Header />

        <Row id="install" title="🍺 Tap it">
          <div className={styles.full}>
            <Copyable command={INSTALL} />
          </div>
          <div>
            <p>
              Formulae here share core's names, so install them fully qualified:{" "}
              <code>macos-intel/tap/&lt;name&gt;</code>. A bare name installs
              core's version.
            </p>
          </div>
          <div>
            <p>In a Brewfile:</p>
            <Copyable command={`tap "macos-intel/tap", trusted: true\nbrew "macos-intel/tap/cmake"`} />
          </div>
        </Row>

        <Row id="what" title="🔧 What does it do?">
          <div>
            <p>
              homebrew-core stopped publishing Intel bottles. This tap keeps
              building <code>sequoia</code> bottles for an explicit, growing list
              of core formulae, so you pour them instead of compiling. Tahoe 26
              support is planned.
            </p>
          </div>
          <div>
            <p>
              Formulae core removed, disabled or restricted to arm64 come back
              when they still work on Intel, each with a small reviewed patch.
              Once installed, a formula follows the tap.{" "}
              <Link to="/docs/how-it-works">How it works</Link>.
            </p>
          </div>
        </Row>

        <Row id="bottles" title="📦 On tap now">
          <div className={styles.full}>
            <BottleList />
          </div>
        </Row>

        <Row id="bot" title="🤖 Meet the bot">
          <div>
            <Mascot />
          </div>
          <div className={styles.botText}>
            <p>
              A change to a formula on <code>main</code> triggers a bottle build.
              The homebrew-intel bot builds it on an Intel runner, publishes the
              release and opens the pull request that adds it to the tap.
            </p>
            <p>
              When core bumps a formula you stay on the tap's last published
              version until the new bottle lands: about a day, plus build time.
            </p>
          </div>
        </Row>

        <Row id="warning" title="⚠️ The Intel warning">
          <div>
            <p>
              On Intel, <code>brew install</code> warns that macOS on x86_64 is
              a Tier 3 configuration. It is expected with this tap and stops
              nothing from installing.
            </p>
          </div>
          <div>
            <p>
              Only <code>HOMEBREW_DEVELOPER=1</code> hides it, with side effects.
              The setup script explains them and asks first:
            </p>
            <Copyable command="./scripts/setup-intel.sh" />
            <Link to="/docs/intel-warning">Read more about the warning</Link>
          </div>
        </Row>

        <section className={styles.credits}>
          <p>
            Homebrew plans to stop running on Intel in or after September 2027.
            This project ends then, unless a separate decision extends it.
          </p>
          <p>BSD 2-Clause, like Homebrew. Formulae are derived from homebrew-core.</p>
        </section>
      </main>
    </Layout>
  );
}
